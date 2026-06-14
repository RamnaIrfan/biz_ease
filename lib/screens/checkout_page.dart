// lib/screens/checkout_page.dart
// ignore_for_file: unused_local_variable

import 'package:biz_ease/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_placed_page.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../widgets/common_image.dart';
import '../models/order_model.dart';
import 'notification_provider.dart';
import '../services/communication_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/push_notification_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color primaryColor = const Color(0xFFD88A1F);
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _isCouponApplied = false;
  String _selectedPaymentMethod = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    // Pre-fill email from AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        _emailController.text = authProvider.email;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Back to Cart'),
                  ),
                ],
              ),
            );
          }

          final double shippingFee = cart.totalPrice >= 3000 ? 0 : 200;
          final double discount = _isCouponApplied ? (cart.totalPrice * 0.10) : 0;
          final totalAmount = cart.totalPrice - discount + shippingFee;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Information Section
                _buildSectionTitle('Delivery Information'),
                _buildDeliveryInfo(),
                
                const SizedBox(height: 24),
                
                // Payment Method Section
                _buildSectionTitle('Payment Method'),
                _buildPaymentMethods(),
                
                const SizedBox(height: 24),
                
                // Coupon Section
                _buildSectionTitle('Coupon Code'),
                _buildCouponSection(),
                
                const SizedBox(height: 24),

                // Order Summary Section
                _buildSectionTitle('Order Summary'),
                _buildOrderSummary(cart, totalAmount, discount),
                
                const SizedBox(height: 32),
                
                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_validateForm()) {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        
                        if (!authProvider.isLoggedIn || authProvider.userId == null) {
                          _showError("Please log in to place an order");
                          return;
                        }

                        // Group items by ownerId
                        final Map<String, List<CartItem>> itemsByOwner = {};
                        for (var item in cartProvider.cartItems) {
                          if (!itemsByOwner.containsKey(item.ownerId)) {
                            itemsByOwner[item.ownerId] = [];
                          }
                          itemsByOwner[item.ownerId]!.add(item);
                        }

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        // Reload user to get latest email verification status
                        await authProvider.reloadUser();
                        if (!authProvider.isEmailVerified) {
                          if (context.mounted) Navigator.pop(context);
                          _showError("Please verify your email address to place an order. A verification link has been sent.");
                          await authProvider.sendEmailVerification();
                          return;
                        }

                        try {
                          final String orderNum = _generateOrderNumber();
                          final orderService = OrderService();
                          final productService = ProductService();
                          
                          // Track success for multiple orders
                          int successfulOrders = 0;
                          final int totalOrders = itemsByOwner.length;
                          
                          // Process each owner's items as a separate order
                          for (var entry in itemsByOwner.entries) {
                            final String ownerId = entry.key;
                            final List<CartItem> ownerItems = entry.value;
                            
                            // Calculate subtotal for this owner
                            final double subtotal = ownerItems.fold(0.0, (sum, item) => sum + item.totalPrice);
                            
                            // Split shipping cost equally among all owners in this checkout
                            // (If total >= 3000, shipping is 0)
                            final double totalShipping = cartProvider.totalPrice >= 3000 ? 0 : 200;
                            final double splitShipping = totalShipping / totalOrders;
                            final double discountedSubtotal = _isCouponApplied ? (subtotal * 0.90) : subtotal;
                            final double ownerTotalAmount = discountedSubtotal + splitShipping;

                            final order = OrderModel(
                              id: '', 
                              ownerId: ownerId,
                              customerId: authProvider.userId!,
                              customerName: _nameController.text,
                              customerEmail: _emailController.text,
                              items: ownerItems,
                              totalAmount: ownerTotalAmount,
                              status: OrderStatus.pending,
                              createdAt: DateTime.now(),
                              deliveryAddress: _addressController.text,
                              phoneNumber: _contactController.text,
                              paymentMethod: _selectedPaymentMethod,
                            );

                            await orderService.createOrder(order);
                            successfulOrders++;
                          }

                          // Send confirmation email (Optional)
                          try {
                            final commsService = CommunicationService();
                            await commsService.sendOrderConfirmationEmail(
                              customerName: _nameController.text,
                              customerEmail: _emailController.text,
                              orderNumber: orderNum,
                              totalAmount: totalAmount,
                            );
                          } catch (e) {
                            debugPrint('Failed to send email confirmation: $e');
                          }

                          // Trigger notification
                          if (context.mounted) {
                            Provider.of<NotificationProvider>(context, listen: false).addNotification(
                              title: 'Order Placed',
                              message: 'Order is placed and is pending. Order #${orderNum.substring(0, 8)} 🚚',
                              type: 'order',
                            );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context); // Remove loading

                          // Navigate to OrderPlacedPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPlacedPage(
                                orderNumber: orderNum,
                                totalAmount: totalAmount, // Show the overall total to customer
                                paymentMethod: _selectedPaymentMethod,
                              ),
                            ),
                          ).then((_) {
                            // Clear cart after navigation without returning stock
                            cartProvider.clearCart(returnStock: false);
                          });

                        } catch (e) {
                          if (context.mounted) Navigator.pop(context); // Remove loading
                          _showError("Failed to place order: $e");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(controller: _addressController, label: 'Address', hintText: 'Enter your delivery address', icon: Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, label: 'Email', hintText: 'Enter your email address', icon: Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(controller: _nameController, label: 'Name', hintText: 'Enter your full name', icon: Icons.person),
            const SizedBox(height: 16),
            _buildTextField(controller: _contactController, label: 'Contact', hintText: 'Enter your phone number', icon: Icons.phone, keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final List<Map<String, dynamic>> paymentMethods = [
      {'icon': Icons.money, 'name': 'Cash on Delivery', 'color': Colors.orange},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: paymentMethods.map((method) {
            final methodName = method['name'] as String;
            final methodIcon = method['icon'] as IconData;
            final methodColor = method['color'] as Color;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = methodName),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == methodName ? primaryColor.withAlpha((0.1 * 255).toInt()) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedPaymentMethod == methodName ? primaryColor : Colors.grey.shade300,
                    width: _selectedPaymentMethod == methodName ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: methodColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(methodIcon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      methodName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedPaymentMethod == methodName ? FontWeight.bold : FontWeight.normal,
                        color: _selectedPaymentMethod == methodName ? primaryColor : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedPaymentMethod == methodName) Icon(Icons.check_circle, color: primaryColor),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _isCouponApplied 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                ),
                enabled: !_isCouponApplied,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isCouponApplied ? () {
                setState(() {
                  _isCouponApplied = false;
                  _couponController.clear();
                });
              } : () {
                if (_couponController.text.trim().toUpperCase() == 'BIZEASE10') {
                  setState(() {
                    _isCouponApplied = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon applied successfully! 10% discount added.'), backgroundColor: Colors.green)
                  );
                } else {
                  _showError('Invalid coupon code');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCouponApplied ? Colors.red : primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text(_isCouponApplied ? 'Remove' : 'Apply', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart, double totalAmount, double discount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Items List
            ...cart.cartItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: CommonImage(
                          imageUrl: item.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${item.price} × ${item.quantity}', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text('Rs. ${_formatPrice(item.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            // Price Breakdown
            _buildPriceRow('Subtotal', 'Rs. ${_formatPrice(cart.totalPrice)}'),
            if (_isCouponApplied) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Discount (10%)', '- Rs. ${_formatPrice(discount)}', valueColor: Colors.red),
            ],
            const SizedBox(height: 8),
            _buildPriceRow(
              'Shipping', 
              cart.totalPrice >= 3000 ? 'FREE' : 'Rs. 200',
              valueColor: cart.totalPrice >= 3000 ? Colors.green : Colors.black87,
            ),
            const SizedBox(height: 12),
            const Divider(height: 24),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Rs. ${_formatPrice(totalAmount)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value, 
          style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
        ),
      ],
    );
  }

  bool _validateForm() {
    if (_addressController.text.isEmpty) {
      _showError('Please enter your delivery address');
      return false;
    }
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email address');
      return false;
    }
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (_contactController.text.isEmpty || _contactController.text.length < 10) {
      _showError('Please enter a valid contact number (at least 10 digits)');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    return 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } else {
      return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(\.|$))'),
        (Match m) => '${m[1]},',
      );
    }
  }
}