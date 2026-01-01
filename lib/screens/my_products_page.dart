import 'package:biz_ease/screens/add_new_product_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../screens/auth_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/common_image.dart';

class MyProductsPage extends StatelessWidget {
  const MyProductsPage({super.key});

  static const orange = Color(0xFFD88A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // Filter functionality
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final ownerId = authProvider.userId;
                  if (ownerId == null) return const Center(child: Text("Please login first"));

                  return StreamBuilder<List<ProductModel>>(
                    stream: ProductService().getProductsByOwner(ownerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data ?? [];
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${products.length} ${products.length == 1 ? 'Product' : 'Products'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: products.isEmpty
                                ? const Center(child: Text("No products found. Add your first product!"))
                                : ListView.builder(
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      return _productCard(context, products[index]);
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddNewProductPage(),
            ),
          );
        },
        backgroundColor: orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _productCard(BuildContext context, ProductModel product) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CommonImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(currencyFormat.format(product.price)),
            Text(
              '${product.stock} in stock',
              style: TextStyle(
                color: product.stock <= 5 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteProduct(context, product.id);
            } else if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNewProductPage(product: product),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context, String productId) async {
    try {
      await ProductService().deleteProduct(productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}