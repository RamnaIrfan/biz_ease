import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/owner_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../screens/auth_provider.dart';
import 'owner_profile_page.dart';
import 'my_products_page.dart'; 
import 'add_new_product_page.dart'; 
import 'owner_orders_page.dart';

class OwnerDashboardPage extends StatelessWidget {
  final OwnerModel owner;
  const OwnerDashboardPage({super.key, required this.owner});

  static const orange = Color(0xFFD88A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${owner.fullName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Manage your store with ease",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerProfilePage(owner: owner),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// STATS GRID
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  final ownerId = auth.userId;
                  if (ownerId == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<OrderModel>>(
                    stream: OrderService().getOwnerOrders(ownerId),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final orders = orderSnapshot.data ?? [];
                      final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
                      
                      return StreamBuilder<List>(
                        stream: ProductService().getProductsByOwner(ownerId),
                        builder: (context, productSnapshot) {
                          if (productSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final productCount = productSnapshot.data?.length ?? 0;

                          return StreamBuilder<double>(
                            stream: OrderService().getOwnerRevenue(ownerId),
                            builder: (context, revenueSnapshot) {
                              if (revenueSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final revenue = revenueSnapshot.data ?? 0.0;
                              final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

                              return GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 2,
                                childAspectRatio: 1.6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _statCard("Products", productCount.toString(), Icons.inventory),
                                  _statCard("Orders", orders.length.toString(), Icons.shopping_cart),
                                  _statCard("Revenue", currencyFormat.format(revenue), Icons.payments),
                                  _statCard("Pending", pendingCount.toString(), Icons.pending),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              /// QUICK ACTIONS
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _buildActionButton(context, Icons.inventory_2, "My Products"),
              _buildActionButton(context, Icons.sync, "Sync Sample Products"),
              _buildActionButton(context, Icons.receipt_long, "Orders & Sales"),
              

              const SizedBox(height: 16),

              /// RECENT ORDERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Orders",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerOrdersPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "View All",
                      style: TextStyle(color: Color(0xFFD88A1F)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  final ownerId = auth.userId;
                  if (ownerId == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<OrderModel>>(
                    stream: OrderService().getRecentOwnerOrders(ownerId, limit: 5),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "No orders yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          Color statusColor = Colors.grey;
                          IconData statusIcon = Icons.pending;
                          
                          switch (order.status) {
                            case OrderStatus.pending:
                              statusColor = Colors.orange;
                              statusIcon = Icons.pending;
                              break;
                            case OrderStatus.processing:
                              statusColor = Colors.blue;
                              statusIcon = Icons.autorenew;
                              break;
                            case OrderStatus.shipped:
                              statusColor = Colors.blueAccent;
                              statusIcon = Icons.local_shipping;
                              break;
                            case OrderStatus.delivered:
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case OrderStatus.cancelled:
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              break;
                            case OrderStatus.confirmed:
                              statusColor = Colors.indigo;
                              statusIcon = Icons.thumb_up;
                              break;
                          }

                          return _orderTile(
                            order.customerName,
                            order.statusText,
                            statusColor,
                            statusIcon,
                            order.totalPrice,
                            order.orderDate,
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              /// LOW STOCK
              const Text(
                "Low Stock Alert",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  final ownerId = auth.userId;
                  if (ownerId == null) {
                    return const SizedBox();
                  }

                  return StreamBuilder<List>(
                    stream: ProductService().getLowStockProducts(ownerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final lowStockProducts = snapshot.data ?? [];
                      if (lowStockProducts.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "All products have sufficient stock",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: lowStockProducts.map((product) {
                            return _lowStockItem(
                              product['name'] ?? 'Unknown Product',
                              'Only ${product['stock'] ?? 0} left',
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: orange, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String text) {
    VoidCallback onPressed;
    
    switch (text) {
      case "Add New Product":
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddNewProductPage(),
            ),
          );
        };
        break;
      case "My Products":
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyProductsPage(),
            ),
          );
        };
        break;
      case "Orders & Sales":
        onPressed = () {
          final ownerId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (ownerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OwnerOrdersPage(),
              ),
            );
          }
        };
        break;
      case "Restore Sample Products":
        onPressed = () async {
          final ownerId = Provider.of<AuthProvider>(context, listen: false).userId;
          try {
            await ProductService().seedSampleProducts(ownerId ?? 'system');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sample products added to Home Page and your Shop!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        };
        break;
      case "Sync Sample Products":
        onPressed = () async {
          final ownerId = Provider.of<AuthProvider>(context, listen: false).userId;
          if (ownerId == null) return;
          
          // Show progress dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            await ProductService().cleanupAndSeedSampleProducts(ownerId);
            if (context.mounted) Navigator.pop(context); // Remove loader
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Samples synced and duplicates cleaned up!')),
              );
            }
          } catch (e) {
            if (context.mounted) Navigator.pop(context); // Remove loader
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        };
        break;
      default:
        onPressed = () {};
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _orderTile(
    String customerName,
    String status,
    Color statusColor,
    IconData statusIcon,
    double totalAmount,
    DateTime orderDate,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(orderDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lowStockItem(String name, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            qty,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}