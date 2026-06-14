import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'carts';

  /// Saves or updates the entire cart for a user
  Future<void> saveCart(String userId, List<CartItem> items) async {
    try {
      await _firestore.collection(_collection).doc(userId).set({
        'updatedAt': FieldValue.serverTimestamp(),
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      throw 'Failed to save cart: $e';
    }
  }

  /// Fetches the user's cart from Firestore
  Future<Map<String, dynamic>?> getCart(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Failed to fetch cart: $e');
      return null;
    }
  }

  /// Deletes the user's cart
  Future<void> deleteCart(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw 'Failed to delete cart: $e';
    }
  }
}
