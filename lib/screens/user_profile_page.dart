// screens/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'order_page.dart';
import 'wishlist_page.dart';
import 'settings_page.dart';
import 'wishlist_provider.dart';
import 'notification_provider.dart';
import 'order_provider.dart';
import 'login_customer.dart';
import 'signup_customer.dart';
import '../models/product_model.dart';
import '../models/wishlist_model.dart';
import '../models/cart_item.dart';
import '../services/product_service.dart';
import '../widgets/common_image.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(AuthProvider authProvider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 500,
    );

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = authProvider.userId;
      if (userId == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await authProvider.updateProfilePicture(downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // If user is NOT logged in, show login/signup options
    if (!authProvider.isLoggedIn) {
      Provider.of<WishlistProvider>(context, listen: false).clear();
      Provider.of<OrderProvider>(context, listen: false).clear();
      return _buildNotLoggedInView(context);
    }
    
    // User IS logged in, show profile
    if (authProvider.userId != null) {
      Provider.of<WishlistProvider>(context, listen: false).init(authProvider.userId!);
      Provider.of<OrderProvider>(context, listen: false).init(authProvider.userId!);
    }
    
    return _buildProfileView(context, authProvider);
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFD88A1F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'You are not logged in',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please sign up or login to access your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginCustomerPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD88A1F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupCustomerPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD88A1F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFD88A1F)),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(color: Color(0xFFD88A1F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, AuthProvider authProvider) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFD88A1F),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                   Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFD88A1F).withAlpha((0.2 * 255).toInt()),
                        backgroundImage: authProvider.profilePictureUrl != null 
                            ? NetworkImage(authProvider.profilePictureUrl!) 
                            : null,
                        child: authProvider.profilePictureUrl == null 
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFFD88A1F),
                              )
                            : null,
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD88A1F),
                            strokeWidth: 2,
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadImage(authProvider),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD88A1F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            authProvider.userType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: const Color(0xFFD88A1F),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFD88A1F)),
                    onPressed: () {
                      _showEditProfileDialog(context, authProvider);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick Stats
            Row(
              children: [
                Consumer<OrderProvider>(
                  builder: (context, orders, child) {
                    return _statCard("Orders", "${orders.count}", Icons.shopping_bag, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderPage(),
                        ),
                      );
                    });
                  },
                ),
                Consumer<WishlistProvider>(
                  builder: (context, wishlist, child) {
                    return _statCard("Wishlist", "${wishlist.count}", Icons.favorite, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistPage(),
                        ),
                      );
                    });
                  },
                ),
                _statCard("Cart", "${cartProvider.totalItems}", Icons.shopping_cart, () {
                  // Navigate to cart page
                }),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Menu Options
            _menuSection(context),
            
            const SizedBox(height: 30),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog(context, authProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recommended Products Section
            _buildRecommendedSection(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Recommended for You",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: StreamBuilder<List<ProductModel>>(
            stream: ProductService().getAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Center(child: Text("No suggestions yet"));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    margin: EdgeInsets.only(
                      right: index == products.length - 1 ? 0 : 12,
                    ),
                    child: _buildProductCard(context, products[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    const primaryColor = Color(0xFFD88A1F);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image + Wishlist Icon
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: CommonImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Consumer<WishlistProvider>(
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
                          id: '', // Will be set by Firestore
                          productId: product.id,
                          ownerId: product.ownerId,
                          name: product.name,
                          price: currencyFormat.format(product.price),
                          image: product.imageUrl ?? '',
                          userId: auth.userId!,
                          createdAt: DateTime.now(),
                        );
                        wishlist.toggleWishlist(item);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isWishlisted 
                              ? '${product.name} removed from wishlist' 
                              : '${product.name} added to wishlist'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: isWishlisted ? Colors.red : Colors.green,
                          ),
                        );
                      },
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha((0.9 * 255).toInt()),
                        padding: EdgeInsets.zero,
                      ),
                      iconSize: 32,
                    );
                  },
                ),
              ),
            ],
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(product.price),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                // Add to Cart Simple Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final cartItem = CartItem(
                        id: product.id,
                        ownerId: product.ownerId,
                        name: product.name,
                        price: currencyFormat.format(product.price),
                        image: product.imageUrl ?? '',
                      );
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      cart.addToCart(cartItem);

                      // Trigger notification
                      Provider.of<NotificationProvider>(context, listen: false).addNotification(
                        title: 'Item Added to Cart',
                        message: '${product.name} has been added to your cart 🛒',
                        type: 'cart',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: const Size(0, 24),
                    ),
                    child: const Text(
                      'Cart',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFFD88A1F), size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.shopping_bag,
        'title': 'My Orders',
        'subtitle': 'View and track your orders',
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  OrderPage(),
          ),
        ),
      },
      {
        'icon': Icons.favorite,
        'title': 'My Wishlist',
        'subtitle': 'Your saved items',
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WishlistPage(),
          ),
        ),
      },
      {
        'icon': Icons.settings,
        'title': 'Settings',
        'subtitle': 'App settings and preferences',
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        ),
      },
    ];

    return Column(
      children: menuItems.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: const Color(0xFFD88A1F),
            ),
            title: Text(item['title'] as String),
            subtitle: Text(item['subtitle'] as String),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: item['route'] as void Function(),
          ),
        );
      }).toList(),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    TextEditingController nameController = TextEditingController(text: authProvider.username);
    TextEditingController emailController = TextEditingController(text: authProvider.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authProvider.updateProfile(
                nameController.text.trim(),
                emailController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD88A1F),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
