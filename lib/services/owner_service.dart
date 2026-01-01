import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_model.dart';

class OwnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'owners';

  // Create a new owner (business registration)
  Future<void> createOwner(OwnerModel owner) async {
    try {
      await _firestore.collection(_collection).doc(owner.id).set(owner.toMap());
    } catch (e) {
      throw 'Failed to register business: $e';
    }
  }

  // Get owner by ID
  Future<OwnerModel?> getOwner(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(uid).get();
      
      if (doc.exists) {
        return OwnerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get business details: $e';
    }
  }

  // Check if owner exists (business is registered)
  Future<bool> ownerExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
