import 'package:biz_ease/models/cart_item.dart';
import 'package:biz_ease/models/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'order_provider.dart';
import 'auth_provider.dart';
import 'cart_page.dart';
import 'wishlist_page.dart';
import 'user_profile_page.dart';
import 'order_page.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';
import '../widgets/common_image.dart';
import 'recent_provider.dart';
import 'notification_provider.dart';
import 'notification_page.dart';
import 'product_details_page.dart';

// Remove this import since we're not using OrderPage from home
// import 'order_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFFD88A1F);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isShowingFlashSale = false;
  bool _isShowingRecent = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesKey = GlobalKey();
  
  // Removed hardcoded _allProducts

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn && auth.userId != null) {
      Provider.of<WishlistProvider>(context, listen: false).init(auth.userId!);
      Provider.of<OrderProvider>(context, listen: false).init(auth.userId!);
      Provider.of<NotificationProvider>(context, listen: false).init(auth.userId!);
    } else {
      Provider.of<WishlistProvider>(context, listen: false).clear();
      Provider.of<OrderProvider>(context, listen: false).clear();
      Provider.of<NotificationProvider>(context, listen: false).clear();
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: (_searchQuery.isNotEmpty || _selectedCategory != null || _isShowingFlashSale || _isShowingRecent)
                  ? _buildSearchResults() 
                  : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0, // Set current index to 0 (Home)
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        const BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
        BottomNavigationBarItem(
          icon: Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cart.totalItems > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: "Cart",
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Order"),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0: // Home
            // Already on home page, do nothing
            break;
          case 1: // Categories
            // Clear search/filter state if active
            if (_searchQuery.isNotEmpty || _selectedCategory != null || _isShowingFlashSale || _isShowingRecent) {
              setState(() {
                _searchController.text = '';
                _searchQuery = '';
                _selectedCategory = null;
                _isShowingFlashSale = false;
                _isShowingRecent = false;
              });
            }
            
            // Scroll to categories section in home content
            Future.delayed(const Duration(milliseconds: 100), () {
              final context = _categoriesKey.currentContext;
              if (context != null) {
                Scrollable.ensureVisible(
                  context, 
                  duration: const Duration(seconds: 1), 
                  curve: Curves.easeInOut
                );
              }
            });
            break;
          case 2: // Cart
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
            break;
          case 3: // Order - Show a placeholder or simple orders page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderPage()),
            );
            break;
          case 4: // Profile
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfilePage()),
            );
            break;
        }
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo or App Name
              const SizedBox(width: 10),
              const Text(
                'BizEase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
               Consumer<NotificationProvider>(
                builder: (context, notifications, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationPage()),
                          );
                        },
                      ),
                      if (notifications.unreadCount > 0)
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
                              '${notifications.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
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
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserProfilePage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFD88A1F)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search products...",
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _isShowingFlashSale = false;
                        _isShowingRecent = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSearchResults() {
  String title = _isShowingRecent
      ? 'Recently Viewed'
      : _isShowingFlashSale
          ? 'Flash Sale - 50% OFF'
          : _selectedCategory != null 
              ? 'Category: $_selectedCategory' 
              : 'Search Results';
      
  Stream<List<ProductModel>> stream;
  if (_isShowingRecent) {
    // For "Recent", we don't need a stream since it's in memory, but to keep UI consistent:
    final recentProducts = Provider.of<RecentProvider>(context, listen: false).recentProducts;
    stream = Stream.value(recentProducts);
  } else if (_isShowingFlashSale) {
    stream = ProductService().getAllProducts();
  } else if (_selectedCategory != null) {
    stream = ProductService().getProductsByCategory(_selectedCategory!);
  } else {
    stream = ProductService().searchProducts(_searchQuery);
  }

  return StreamBuilder<List<ProductModel>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }
      List<ProductModel> products = snapshot.data ?? [];

      if (_isShowingFlashSale) {
        products = products.take(10).toList();
      }

      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_selectedCategory != null ? Icons.category_outlined : Icons.search_off, 
                   size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _selectedCategory != null 
                    ? 'No products in "$_selectedCategory"'
                    : 'No results for "$_searchQuery"',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text('Try something else'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = null;
                    _isShowingFlashSale = false;
                    _isShowingRecent = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$title (${products.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedCategory = null;
                      _isShowingFlashSale = false;
                      _isShowingRecent = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.55, // Increased height for 3rd column
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index], isDiscounted: _isShowingFlashSale);
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Welcome Back 👋",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildBanner(),
          _buildCategories(),
          _buildQuickActions(),
          _productSection("Flash Deals 🔥", isFlashSale: true),
          _productSection("Recommended for You", isFlashSale: false),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isShowingFlashSale = true;
            _isShowingRecent = false;
            _selectedCategory = null;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Image.asset(
                'assets/sale.jpg',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withAlpha(150), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              const Positioned.fill(
                child: Center(
                  child: Text(
                    "FLASH SALE\nUP TO 50% OFF",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.electrical_services, 'name': 'Electronics'},
      {'icon': Icons.card_giftcard, 'name': 'Gifts'},
      {'icon': Icons.shopping_bag, 'name': 'Fashion'},
      {'icon': Icons.spa, 'name': 'Beauty'},
      {'icon': Icons.home, 'name': 'Home'},
      {'icon': Icons.watch, 'name': 'Accessories'},
    ];

    return Padding(
      key: _categoriesKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Browse Categories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'] as String;
                      _searchQuery = '';
                      _isShowingFlashSale = false;
                      _isShowingRecent = false;
                      _searchController.clear();
                    }); 
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            category['icon'] as IconData,
                            color: primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Consumer<OrderProvider>(
            builder: (context, orders, child) {
              return _QuickCard(
                icon: Icons.shopping_bag,
                title: "Orders",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderPage())),
              );
            },
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              return _QuickCard(
                icon: Icons.favorite,
                title: "Wishlist",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage())),
              );
            },
          ),
          _QuickCard(
            icon: Icons.history,
            title: "Recent",
            onTap: () {
              setState(() {
                _isShowingRecent = true;
                _isShowingFlashSale = false;
                _selectedCategory = null;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _productSection(String title, {bool isFlashSale = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210, // Increased buffer to prevent overflow
            child: StreamBuilder<List<ProductModel>>(
              stream: ProductService().getAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allProducts = snapshot.data ?? [];
                
                if (allProducts.isEmpty) {
                  return const Center(child: Text("No products available"));
                }

                // Simple logic to split products to avoid duplicates in UI
                // Flash sale gets first half (or filtered), Recommended gets second half
                // Show 10 items for Flash sale, other half for Recommended
                List<ProductModel> productsToShow;
                if (isFlashSale) {
                  productsToShow = allProducts.take(10).toList();
                } else {
                  // Skip 10 or just show second half to avoid too much overlap
                  int skipCount = allProducts.length > 10 ? 10 : (allProducts.length / 2).floor();
                  productsToShow = allProducts.skip(skipCount).toList();
                }
                
                if (productsToShow.isEmpty) {
                   return const Center(child: Text("Check back later for more!"));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: productsToShow.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 140,
                      margin: EdgeInsets.only(
                        right: index == productsToShow.length - 1 ? 0 : 12,
                      ),
                      child: _buildProductCard(productsToShow[index], isDiscounted: isFlashSale),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProductCard(ProductModel product, {bool isDiscounted = false}) {
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final double displayPrice = isDiscounted ? product.price * 0.5 : product.price;

  return Card(
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: () {
        Provider.of<RecentProvider>(context, listen: false).addProduct(product);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
              isDiscounted: isDiscounted,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 80,
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
                          isWishlisted 
                            ? '${product.name} removed from wishlist' 
                            : '${product.name} added to wishlist',
                          isWishlisted ? Icons.favorite_border : Icons.favorite,
                        );
                      },
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha((0.9 * 255).toInt()),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                      ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Product Price
                if (isDiscounted) ...[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 9,
                        ),
                      ),
                      const Text(
                        "50% OFF",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(displayPrice),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  Text(
                    currencyFormat.format(product.price),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Slightly larger base price
                    ),
                  ),
                const SizedBox(height: 8),
                // Add to Cart Button (Larger)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final cartItem = CartItem(
                        id: product.id,
                        ownerId: product.ownerId,
                        name: product.name,
                        price: currencyFormat.format(displayPrice),
                        image: product.imageUrl ?? '',
                      );
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      cart.addToCart(cartItem);
                      
                      Provider.of<NotificationProvider>(context, listen: false).addNotification(
                        title: 'Item Added to Cart',
                        message: '${product.name} has been added to your cart 🛒',
                        type: 'cart',
                      );
                      
                      _showSuccessDialog('${product.name} added to cart', Icons.shopping_cart);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32), // Slightly reduced from 36
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 11, // Larger text
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFD88A1F), size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}