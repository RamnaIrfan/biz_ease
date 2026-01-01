import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'customers';

  // Create a new customer
  Future<void> createCustomer(CustomerModel customer) async {
    try {
      await _firestore.collection(_collection).doc(customer.id).set(customer.toMap());
    } catch (e) {
      throw 'Failed to create customer: $e';
    }
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomer(String customerId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(customerId).get();
      
      if (doc.exists) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get customer: $e';
    }
  }

  // Get customer by email
  Future<CustomerModel?> getCustomerByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get customer by email: $e';
    }
  }

  // Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _firestore.collection(_collection).doc(customer.id).update(
        customer.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw 'Failed to update customer: $e';
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).delete();
    } catch (e) {
      throw 'Failed to delete customer: $e';
    }
  }

  // Get all customers (for admin/business owner)
  Stream<List<CustomerModel>> getAllCustomers() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if customer exists
  Future<bool> customerExists(String customerId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(customerId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
