import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<OrderModel> get orders => _orders;
  int get count => _orders.length;

  void init(String userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _subscription?.cancel();
    
    _subscription = _orderService.getCustomerOrders(userId).listen(
      (newOrders) {
        _orders = newOrders;
        notifyListeners();
      },
      onError: (error) {
        print('OrderProvider Error: $error');
      },
    );
  }

  void clear() {
    if (_currentUserId == null) return;
    
    _subscription?.cancel();
    _subscription = null;
    _orders = [];
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
