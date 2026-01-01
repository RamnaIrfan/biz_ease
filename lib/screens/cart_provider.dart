// cart_provider.dart
import 'package:biz_ease/models/cart_item.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addToCart(CartItem item) {
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += 1;
    } else {
      _cartItems.add(CartItem(
        id: item.id,
        ownerId: item.ownerId,
        name: item.name,
        price: item.price,
        image: item.image,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void increaseQuantity(String id) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index].quantity += 1;
      notifyListeners();
    }
  }

  void decreaseQuantity(String id) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}