import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();
  List<WishlistItem> _items = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<WishlistItem> get items => _items;
  int get count => _items.length;

  void init(String userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _subscription?.cancel();
    
    _subscription = _wishlistService.getWishlistStream(userId).listen(
      (newItems) {
        _items = newItems;
        notifyListeners();
      },
      onError: (error) {
        print('WishlistProvider Error: $error');
      },
    );
  }

  Future<void> toggleWishlist(WishlistItem item) async {
    final index = _items.indexWhere((i) => i.productId == item.productId);
    if (index >= 0) {
      await _wishlistService.removeFromWishlist(item.userId, item.productId);
    } else {
      await _wishlistService.addToWishlist(item);
    }
  }

  bool isWishlisted(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  void clear() {
    if (_currentUserId == null) return;
    
    _subscription?.cancel();
    _subscription = null;
    _items = [];
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
