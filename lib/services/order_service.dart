import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // Create a new order
  Future<String> createOrder(OrderModel order) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create order: $e';
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(orderId).get();
      
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get order: $e';
    }
  }

  Stream<List<OrderModel>> getCustomerOrders(String customerId) {
    return _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in-memory to avoid needing a composite index
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Get orders for a specific owner
  Stream<List<OrderModel>> getOwnerOrders(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Get recent orders for a specific owner with limit
  Stream<List<OrderModel>> getRecentOwnerOrders(String ownerId, {int limit = 5}) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in-memory
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply limit
      return orders.take(limit).toList();
    });
  }

  // Get all orders (for business owner/admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get orders by status
  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in-memory
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      // If status is delivered, set deliveredAt timestamp
      if (status == OrderStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.now();
      }

      await _firestore.collection(_collection).doc(orderId).update(updateData);
    } catch (e) {
      throw 'Failed to update order status: $e';
    }
  }

  // Update entire order
  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore.collection(_collection).doc(order.id).update(
        order.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw 'Failed to update order: $e';
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.cancelled);
    } catch (e) {
      throw 'Failed to cancel order: $e';
    }
  }

  // Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).delete();
    } catch (e) {
      throw 'Failed to delete order: $e';
    }
  }

  // Get order count for a customer
  Future<int> getCustomerOrderCount(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get total revenue (for business owner)
  Stream<double> getOwnerRevenue(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          final validStatuses = [
            OrderStatus.delivered.name,
            OrderStatus.confirmed.name,
            OrderStatus.processing.name,
            OrderStatus.shipped.name,
          ];
          
          for (var doc in snapshot.docs) {
            var data = doc.data();
            if (validStatuses.contains(data['status'])) {
              total += (data['totalAmount'] ?? 0.0).toDouble();
            }
          }
          return total;
        });
  }
}
