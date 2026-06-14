// models/cart_item.dart
class CartItem {
  final String id;
  final String ownerId;
  String name;
  String price; // This is the formatted price string
  String image;
  int quantity;
  bool isDiscounted;

  CartItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
    this.isDiscounted = false,
  });

  // Helper method to get numeric price for calculations
  double get numericPrice {
    try {
      // Remove "Rs. ", commas, and any other non-numeric characters except dot
      String cleanPrice = price.replaceAll('Rs.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method to get total price for this item
  double get totalPrice => numericPrice * quantity;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'isDiscounted': isDiscounted,
    };
  }

  // Create from Firestore document
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '0',
      image: map['image'] ?? '',
      quantity: map['quantity'] ?? 1,
      isDiscounted: map['isDiscounted'] ?? false,
    );
  }
}
