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
  final int? lastAlertedStock;

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
    this.lastAlertedStock,
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
      'lastAlertedStock': lastAlertedStock,
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
      lastAlertedStock: map['lastAlertedStock'],
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
    int? lastAlertedStock,
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
      lastAlertedStock: lastAlertedStock ?? this.lastAlertedStock,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
