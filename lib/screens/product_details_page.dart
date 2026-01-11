import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';
import '../models/wishlist_model.dart';
import '../models/owner_model.dart';
import '../services/owner_service.dart';
import '../widgets/common_image.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;
  final bool isDiscounted;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.isDiscounted = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  final Color primaryColor = const Color(0xFFD88A1F);

  void _incrementQuantity() {
    setState(() {
      if (_quantity < widget.product.stock) {
        _quantity++;
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  void _showSuccessDialog(String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 50),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final double displayPrice = widget.isDiscounted ? widget.product.price * 0.5 : widget.product.price;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: Hero(
                tag: 'product_${widget.product.id}',
                child: CommonImage(
                  imageUrl: widget.product.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Shop Name (Owner)
                  FutureBuilder<OwnerModel?>(
                    future: OwnerService().getOwner(widget.product.ownerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading shop info...', style: TextStyle(color: Colors.grey));
                      }
                      final shopName = snapshot.data?.businessName ?? 'Special Store';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store, size: 16, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Sold by $shopName',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price Section
                  Row(
                    children: [
                      if (widget.isDiscounted) ...[
                        Text(
                          currencyFormat.format(widget.product.price),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        currencyFormat.format(displayPrice),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (widget.isDiscounted) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '50% OFF',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  Text(
                    widget.product.stock > 0 ? 'In Stock (${widget.product.stock} available)' : 'Out of Stock',
                    style: TextStyle(
                      color: widget.product.stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Divider(height: 40),
                  
                  // Description
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Quantity and Wishlist
                  Row(
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _decrementQuantity,
                              icon: const Icon(Icons.remove),
                              color: primaryColor,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: _incrementQuantity,
                              icon: const Icon(Icons.add),
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Consumer<WishlistProvider>(
                        builder: (context, wishlist, child) {
                          final isWishlisted = wishlist.isWishlisted(widget.product.id);
                          return IconButton(
                            onPressed: () {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (!auth.isLoggedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please login to add to wishlist')),
                                );
                                return;
                              }
                              
                              final item = WishlistItem(
                                id: '',
                                productId: widget.product.id,
                                ownerId: widget.product.ownerId,
                                name: widget.product.name,
                                price: currencyFormat.format(widget.product.price),
                                image: widget.product.imageUrl ?? '',
                                userId: auth.userId!,
                                createdAt: DateTime.now(),
                              );
                              wishlist.toggleWishlist(item);
                              _showSuccessDialog(
                                isWishlisted ? 'Removed from wishlist' : 'Added to wishlist',
                                isWishlisted ? Icons.favorite_border : Icons.favorite,
                              );
                            },
                            icon: Icon(
                              isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: isWishlisted ? Colors.red : Colors.grey,
                            ),
                            iconSize: 32,
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: widget.product.stock > 0 ? () {
              final cartItem = CartItem(
                id: widget.product.id,
                ownerId: widget.product.ownerId,
                name: widget.product.name,
                price: currencyFormat.format(displayPrice),
                image: widget.product.imageUrl ?? '',
                quantity: _quantity,
              );
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.addToCart(cartItem);
              
              Provider.of<NotificationProvider>(context, listen: false).addNotification(
                title: 'Item Added to Cart',
                message: '${widget.product.name} (x$_quantity) has been added 🛒',
                type: 'cart',
              );
              
              _showSuccessDialog('${widget.product.name} added to cart', Icons.shopping_cart);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.product.stock > 0 ? 'ADD TO CART - ${currencyFormat.format(displayPrice * _quantity)}' : 'OUT OF STOCK',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
