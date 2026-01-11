import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'notification_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Create a new product
  Future<void> createProduct(ProductModel product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).set(product.toMap());
      
      // Trigger "New Arrival" or "Discount" notification to all users
      bool isDiscount = product.name.toLowerCase().contains('discount') || 
                       product.description.toLowerCase().contains('discount') ||
                       product.name.toLowerCase().contains('sale') ||
                       product.description.toLowerCase().contains('sale');

      await NotificationService().createNotification(
        userId: 'all', 
        title: isDiscount ? 'Discount Alert! 💸' : 'New Arrival! 🔥',
        message: isDiscount 
            ? "Big savings! ${product.name} is now on sale. Grab it before it's gone!"
            : "${product.name} is now available in ${product.category}. Check it out!",
        type: isDiscount ? 'offer' : 'new_product',
      );
    } catch (e) {
      throw 'Failed to add product: $e';
    }
  }

  // Get all products (for customer home)
  Stream<List<ProductModel>> getAllProducts() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory to be resilient to missing 'createdAt' fields
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Get products by owner (for shop display)
  Stream<List<ProductModel>> getProductsByOwner(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory to avoid composite index requirement
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Update all products to a new owner (Migration helper)
  Future<void> updateAllProductsOwner(String ownerId) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      WriteBatch batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'ownerId': ownerId});
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Migration failed: $e';
    }
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Search products (Improved with client-side filtering for case-insensitivity)
  Stream<List<ProductModel>> searchProducts(String query) {
    // If query is short, we can use a prefix search for initial data
    // but ultimately Firestore is limited for case-insensitive partial matches.
    // For a small/medium codebase, fetching and filtering or using a 'search' field is better.
    
    return _firestore
        .collection(_collection)
        .snapshots() // Fetching all for filtering - in production use a better search index
        .map((snapshot) {
      final q = query.toLowerCase().trim();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .where((product) {
            return product.name.toLowerCase().contains(q) || 
                   product.category.toLowerCase().contains(q);
          })
          .toList();
    });
  }

  // Update product (e.g., stock)
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).update(product.toMap());
    } catch (e) {
      throw 'Failed to update product: $e';
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
    } catch (e) {
      throw 'Failed to delete product: $e';
    }
  }

  // Get low stock products (e.g., stock <= 5)
  Stream<List<Map<String, dynamic>>> getLowStockProducts(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((product) => (product['stock'] ?? 0) <= 5)
          .toList();
    });
  }

  // Seed sample products (for restoration)
  Future<void> seedSampleProducts([String ownerId = 'system']) async {
    final List<Map<String, dynamic>> samples = [
      {
        'name': 'Wireless Headphones',
        'price': 15000.0,
        'stock': 10,
        'category': 'Electronics',
        'description': 'High-quality wireless headphones with noise cancellation.',
        'imageUrl': 'assets/headphone.png',
      },
      {
        'name': 'Matte Lipstick',
        'price': 1200.0,
        'stock': 50,
        'category': 'Beauty',
        'description': 'Long-lasting matte lipstick in various shades.',
        'imageUrl': 'assets/lipstick.png',
      },
      {
        'name': 'Smart Watch',
        'price': 25000.0,
        'stock': 5,
        'category': 'Electronics',
        'description': 'Feature-rich smart watch with health tracking.',
        'imageUrl': 'assets/smartwatch.png',
      },
      {
        'name': 'Summer Dress',
        'price': 4500.0,
        'stock': 20,
        'category': 'Fashion',
        'description': 'Light and comfortable summer dress.',
        'imageUrl': 'assets/dress.png',
      },
      {
        'name': 'Luxury Perfume',
        'price': 8500.0,
        'stock': 15,
        'category': 'Beauty',
        'description': 'Elegant fragrance that lasts all day.',
        'imageUrl': 'assets/perfume.png',
      },
      {
        'name': 'Smartphone',
        'price': 120000.0,
        'stock': 8,
        'category': 'Electronics',
        'description': 'Powerful smartphone with advanced camera system.',
        'imageUrl': 'assets/phone.png',
      },
    ];

    try {
      WriteBatch batch = _firestore.batch();
      for (var sample in samples) {
        // Create a deterministic ID based on owner and product name to avoid duplicates
        final String docId = 'sample_${ownerId}_${sample['name'].toString().toLowerCase().replaceAll(' ', '_')}';
        DocumentReference doc = _firestore.collection(_collection).doc(docId);
        batch.set(doc, {
          ...sample,
          'id': docId,
          'ownerId': ownerId,
          'createdAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw 'Seeding failed: $e';
    }
  }

  // Cleanup and seed (to fix duplicates)
  Future<void> cleanupAndSeedSampleProducts(String ownerId) async {
    final List<String> sampleNames = [
      'Wireless Headphones',
      'Matte Lipstick',
      'Smart Watch',
      'Summer Dress',
      'Luxury Perfume',
      'Smartphone'
    ];

    try {
      // 1. Find and delete existing samples for this owner
      final querySnapshot = await _firestore.collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (sampleNames.contains(data['name'])) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();

      // 2. Re-seed with deterministic IDs
      await seedSampleProducts(ownerId);
    } catch (e) {
      throw 'Cleanup and seeding failed: $e';
    }
  }

  // Reduce product stock
  Future<void> reduceStock(String productId, int quantity) async {
    try {
      DocumentReference docRef = _firestore.collection(_collection).doc(productId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw 'Product does not exist!';
        }
        
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        int currentStock = data['stock'] ?? 0;
        int newStock = currentStock - quantity;
        
        if (newStock < 0) {
          newStock = 0; // Prevent negative stock
        }
        
        transaction.update(docRef, {'stock': newStock});
        
        // Trigger low stock alert if stock is low (e.g., <= 3)
        if (newStock <= 3 && newStock > 0) {
          NotificationService().createNotification(
            userId: data['ownerId'] ?? 'system',
            title: 'Low Stock Alert 📦',
            message: 'Product "${data['name']}" is running low on stock (${newStock} left).',
            type: 'cart',
          );
        }
      });
    } catch (e) {
      throw 'Failed to reduce stock: $e';
    }
  }

  // Find and remove duplicate products for an owner
  Future<int> cleanupDuplicates(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      // Group products by name
      final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> groupedProducts = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').trim().toLowerCase();
        
        if (name.isNotEmpty) {
          if (!groupedProducts.containsKey(name)) {
            groupedProducts[name] = [];
          }
          groupedProducts[name]!.add(doc);
        }
      }

      int deletedCount = 0;
      WriteBatch batch = _firestore.batch();
      bool batchNeedsCommit = false;

      groupedProducts.forEach((name, docs) {
        if (docs.length > 1) {
          // Sort by creation time (keep the oldest)
          docs.sort((a, b) {
             final dataA = a.data();
             final dataB = b.data();
             final tA = dataA['createdAt'] as Timestamp?;
             final tB = dataB['createdAt'] as Timestamp?;
             if (tA == null) return 1;
             if (tB == null) return -1;
             return tA.compareTo(tB);
          });

          // Delete all except the first one (oldest)
          for (int i = 1; i < docs.length; i++) {
             batch.delete(docs[i].reference);
             deletedCount++;
             batchNeedsCommit = true;
          }
        }
      });

      if (batchNeedsCommit) {
        await batch.commit();
      }

      return deletedCount;
    } catch (e) {
      throw 'Failed to cleanup duplicates: $e';
    }
  }

  // Delete all products with a specific name (for cleanup)
  Future<int> deleteProductsByName(String name, String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .where('name', isEqualTo: name)
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        count++;
      }

      await batch.commit();
      return count;
    } catch (e) {
      throw 'Failed to delete products by name: $e';
    }
  }

  // Delete all sample/dummy products for an owner
  Future<int> deleteAllSampleProducts(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      // List of known sample product names
      final sampleNames = [
        'Wireless Headphones',
        'Matte Lipstick',
        'Smart Watch',
        'Summer Dress',
        'Luxury Perfume',
        'Smartphone'
      ];

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final docId = doc.id;
        final name = data['name'] as String?;

        // Delete if ID starts with 'sample_' OR name matches known samples
        if (docId.startsWith('sample_') || (name != null && sampleNames.contains(name))) {
          batch.delete(doc.reference);
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      return count;
    } catch (e) {
      throw 'Failed to delete sample products: $e';
    }
  }
}
