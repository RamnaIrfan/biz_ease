import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String ownerId;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
