import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wishlist_model.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'wishlist';

  // Add to wishlist
  Future<void> addToWishlist(WishlistItem item) async {
    try {       
      // Check if already exists to avoid duplicates
      final existing = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: item.userId)
          .where('productId', isEqualTo: item.productId)
          .get();
      
      if (existing.docs.isEmpty) {
        await _firestore.collection(_collection).add(item.toMap());
      }
    } catch (e) {
      throw 'Failed to add to wishlist: $e';
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw 'Failed to remove from wishlist: $e';
    }
  }

  Stream<List<WishlistItem>> getWishlistStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => WishlistItem.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in-memory to avoid needing a composite index
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }
}
