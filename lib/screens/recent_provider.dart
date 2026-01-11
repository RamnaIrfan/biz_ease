import 'package:flutter/material.dart';
import '../models/product_model.dart';

class RecentProvider with ChangeNotifier {
  final List<ProductModel> _recentProducts = [];

  List<ProductModel> get recentProducts => List.unmodifiable(_recentProducts);

  void addProduct(ProductModel product) {
    // Check if product already exists
    final index = _recentProducts.indexWhere((p) => p.id == product.id);
    
    if (index != -1) {
      // Remove existing to move it to the front
      _recentProducts.removeAt(index);
    }
    
    // Add to the beginning
    _recentProducts.insert(0, product);
    
    // Cap at 10 items
    if (_recentProducts.length > 10) {
      _recentProducts.removeLast();
    }
    
    notifyListeners();
  }

  void clear() {
    _recentProducts.clear();
    notifyListeners();
  }
}
