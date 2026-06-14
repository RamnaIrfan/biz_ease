// cart_provider.dart
import 'dart:async';
import 'package:biz_ease/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import 'package:intl/intl.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final Map<String, StreamSubscription> _productSubscriptions = {};
  
  String? _currentUserId;
  StreamSubscription<User?>? _authSubscription;

  CartProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUserId = user.uid;
        _loadCartFromFirestore();
      } else {
        _currentUserId = null;
        // User logged out. Clear memory cart WITHOUT returning stock (it's safely saved in Firestore).
        _cartItems.clear();
        for (var sub in _productSubscriptions.values) {
          sub.cancel();
        }
        _productSubscriptions.clear();
        notifyListeners();
      }
    });
  }

  Future<void> _loadCartFromFirestore() async {
    if (_currentUserId == null) return;
    
    final cartData = await _cartService.getCart(_currentUserId!);
    if (cartData != null) {
      final Timestamp? updatedAt = cartData['updatedAt'] as Timestamp?;
      final List<dynamic> itemsData = cartData['items'] ?? [];
      
      // Check expiration (48 hours)
      if (updatedAt != null) {
        final DateTime updatedDate = updatedAt.toDate();
        final Duration diff = DateTime.now().difference(updatedDate);
        
        if (diff.inHours >= 48) {
          // Cart expired. Return stock and delete cart.
          for (var itemMap in itemsData) {
            final item = CartItem.fromMap(itemMap);
            try {
              await _productService.increaseStock(item.id, item.quantity);
            } catch (e) {
              debugPrint('Failed to return stock for expired cart item: $e');
            }
          }
          await _cartService.deleteCart(_currentUserId!);
          return; // Cart is cleared, nothing to load.
        }
      }
      
      // Not expired. Load into memory.
      _cartItems.clear();
      for (var itemMap in itemsData) {
        final item = CartItem.fromMap(itemMap);
        _cartItems.add(item);
        _listenToProduct(item.id);
      }
      notifyListeners();
    }
  }

  Future<void> _syncToFirestore() async {
    if (_currentUserId != null && _cartItems.isNotEmpty) {
      await _cartService.saveCart(_currentUserId!, _cartItems);
    } else if (_currentUserId != null && _cartItems.isEmpty) {
      await _cartService.deleteCart(_currentUserId!);
    }
  }

  List<CartItem> get cartItems => _cartItems;
  int get totalItems => _cartItems.fold(0, (total, item) => total + item.quantity);
  
  double get totalPrice {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    for (var sub in _productSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void _listenToProduct(String productId) {
    if (_productSubscriptions.containsKey(productId)) return;
    
    _productSubscriptions[productId] = _productService.getProductStream(productId).listen((product) {
      if (product == null) {
        // Product was deleted externally
        _cartItems.removeWhere((item) => item.id == productId);
        _productSubscriptions[productId]?.cancel();
        _productSubscriptions.remove(productId);
        _syncToFirestore();
        notifyListeners();
      } else {
        // Update product info (price, name, etc.)
        final index = _cartItems.indexWhere((item) => item.id == productId);
        if (index >= 0) {
          bool changed = false;
          final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
          final double currentBasePrice = product.price;
          // ✅ FIXED: Universal Background Discount Logic
          // This ensures the background listener doesn't reset the price to full for sale categories
          final bool shouldBeDiscounted = _cartItems[index].isDiscounted || 
              ['Electronics', 'Beauty', 'Fashion', 'Gifts', 'Makeup'].contains(product.category);
          
          final double finalPrice = shouldBeDiscounted ? currentBasePrice * 0.5 : currentBasePrice;
          
          // Also update the flag to keep it consistent
          if (_cartItems[index].isDiscounted != shouldBeDiscounted) {
             _cartItems[index].isDiscounted = shouldBeDiscounted;
          }
          
          final String newPrice = currencyFormat.format(finalPrice);
          
          if (_cartItems[index].price != newPrice) {
            _cartItems[index].price = newPrice;
            changed = true;
          }
          if (_cartItems[index].name != product.name) {
            _cartItems[index].name = product.name;
            changed = true;
          }
          if (_cartItems[index].image != product.imageUrl) {
            _cartItems[index].image = product.imageUrl ?? '';
            changed = true;
          }
          if (changed) notifyListeners();
        }
      }
    });
  }

  Future<void> addToCart(CartItem item) async {
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    final int quantityToAdd = item.quantity;
    
    try {
      // Reduce stock in Firestore first
      await _productService.reduceStock(item.id, quantityToAdd);
      
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += quantityToAdd;
        // Update price AND discount status to match the newly added item
        _cartItems[existingIndex].price = item.price;
        _cartItems[existingIndex].isDiscounted = item.isDiscounted;
      } else {
        _cartItems.add(item);
        _listenToProduct(item.id);
      }
      await _syncToFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add to cart: $e');
      rethrow;
    }
  }

  Future<void> increaseQuantity(String id) async {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      try {
        await _productService.reduceStock(id, 1);
        _cartItems[index].quantity += 1;
        await _syncToFirestore();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to increase quantity: $e');
        rethrow;
      }
    }
  }

  Future<void> decreaseQuantity(String id) async {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      try {
        await _productService.increaseStock(id, 1);
        if (_cartItems[index].quantity > 1) {
          _cartItems[index].quantity -= 1;
        } else {
          _cartItems.removeAt(index);
          _productSubscriptions[id]?.cancel();
          _productSubscriptions.remove(id);
        }
        await _syncToFirestore();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to decrease quantity: $e');
        rethrow;
      }
    }
  }

  Future<void> removeFromCart(String id) async {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final quantity = _cartItems[index].quantity;
      try {
        await _productService.increaseStock(id, quantity);
        _cartItems.removeAt(index);
        _productSubscriptions[id]?.cancel();
        _productSubscriptions.remove(id);
        await _syncToFirestore();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to remove from cart: $e');
        rethrow;
      }
    }
  }

  Future<void> clearCart({bool returnStock = true}) async {
    if (returnStock) {
      // Return stock for each item if requested
      for (var item in _cartItems) {
        try {
          await _productService.increaseStock(item.id, item.quantity);
        } catch (e) {
          debugPrint('Failed to return stock for ${item.id}: $e');
        }
      }
    }
    _cartItems.clear();
    for (var sub in _productSubscriptions.values) {
      sub.cancel();
    }
    _productSubscriptions.clear();
    await _syncToFirestore();
    notifyListeners();
  }
}