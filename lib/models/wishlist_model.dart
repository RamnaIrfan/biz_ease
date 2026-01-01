import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String id;
  final String productId;
  final String ownerId;
  final String name;
  final String price;
  final String image;
  final String userId;
  final DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.image,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'ownerId': ownerId,
      'name': name,
      'price': price,
      'image': image,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map, String documentId) {
    return WishlistItem(
      id: documentId,
      productId: map['productId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      image: map['image'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
