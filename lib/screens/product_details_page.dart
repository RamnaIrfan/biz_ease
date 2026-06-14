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
import 'cart_page.dart';

import '../services/product_service.dart';

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
  final ProductService _productService = ProductService();

  void _incrementQuantity(int currentStock) {
    if (currentStock <= 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Item out of stock. You cannot add more."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      if (_quantity < currentStock) {
        _quantity++;
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can't add more"),
            backgroundColor: Colors.orange,
          ),
        );
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
    
    return StreamBuilder<ProductModel?>(
      stream: _productService.getProductStream(widget.product.id),
      initialData: widget.product,
      builder: (context, snapshot) {
        final product = snapshot.data ?? widget.product;
        final double displayPrice = widget.isDiscounted ? product.price * 0.5 : product.price;
        
        // Ensure quantity doesn't exceed new stock
        if (_quantity > product.stock && product.stock > 0) {
          _quantity = product.stock;
        } else if (product.stock == 0) {
          _quantity = 1;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            backgroundColor: primaryColor,
            elevation: 0,
            actions: [
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartPage()),
                          );
                        },
                      ),
                      if (cart.totalItems > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${cart.totalItems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
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
                    tag: 'product_${product.id}',
                    child: CommonImage(
                      imageUrl: product.imageUrl,
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
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Shop Name (Owner)
                      FutureBuilder<OwnerModel?>(
                        future: OwnerService().getOwner(product.ownerId),
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
                              currencyFormat.format(product.price),
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
                      Row(
                        children: [
                          Icon(
                            product.stock > 0 ? Icons.check_circle : Icons.error_outline,
                            color: product.stock > 0 ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (product.stock - _quantity) >= 0 
                                ? 'In Stock (${product.stock - _quantity} items)' 
                                : 'Out of Stock',
                            style: TextStyle(
                              color: (product.stock - _quantity) > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (product.stock > 0) ...[
                             const Spacer(),
                             const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text(
                               'Real-time inventory',
                               style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                             ),
                          ],
                        ],
                      ),
                      
                      const Divider(height: 40),
                      
                      // Description
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 22, color: Colors.black87),
                          const SizedBox(width: 10),
                          const Text(
                            'Product Description',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
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
                                  onPressed: product.stock > 0 ? _decrementQuantity : null,
                                  icon: const Icon(Icons.remove),
                                  color: primaryColor,
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: () => _incrementQuantity(product.stock),
                                  icon: const Icon(Icons.add),
                                  color: product.stock > 0 ? primaryColor : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Consumer<WishlistProvider>(
                            builder: (context, wishlist, child) {
                              final isWishlisted = wishlist.isWishlisted(product.id);
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
                                    productId: product.id,
                                    ownerId: product.ownerId,
                                    name: product.name,
                                    price: currencyFormat.format(product.price),
                                    image: product.imageUrl ?? '',
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
                onPressed: product.stock > 0 ? () async {
                  final cartItem = CartItem(
                    id: product.id,
                    ownerId: product.ownerId,
                    name: product.name,
                    price: currencyFormat.format(displayPrice),
                    image: product.imageUrl ?? '',
                    quantity: _quantity,
                    isDiscounted: widget.isDiscounted,
                  );
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await cart.addToCart(cartItem);
                    if (context.mounted) {
                      Navigator.pop(context); // Remove loader
                      
                      Provider.of<NotificationProvider>(context, listen: false).addNotification(
                        title: 'Item Added to Cart',
                        message: '${product.name} (x$_quantity) has been added 🛒',
                        type: 'cart',
                        metadata: {'productId': product.id},
                      );
                      
                      _showSuccessDialog('${product.name} added to cart', Icons.shopping_cart);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Remove loader
                      
                      String errorMsg = e.toString()
                          .replaceAll('Exception: ', '')
                          .replaceAll('Failed to reduce stock: ', '')
                          .trim();
                      
                      // Fallback for Flutter Web "converted Future" errors
                      if (errorMsg.contains('Future') || errorMsg.contains('boxed error')) {
                        errorMsg = "Could not add more. Item might be out of stock.";
                      }

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
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
                      product.stock > 0 ? 'ADD TO CART - ${currencyFormat.format(displayPrice * _quantity)}' : 'OUT OF STOCK',
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
      },
    );
  }
}
