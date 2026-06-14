import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import '../models/notification_model.dart';
import 'cart_page.dart';
import 'product_details_page.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFD88A1F),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(context, notification, notificationProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withAlpha((0.1 * 255).toInt()),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFD88A1F),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          provider.markAsRead(notification.id);
          
          if (notification.type == 'cart') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          } else if ((notification.type == 'new_product' || notification.type == 'offer') && 
                     notification.metadata != null && 
                     notification.metadata!['productId'] != null) {
            
            final productId = notification.metadata!['productId'];
            
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              final product = await ProductService().getProductById(productId);
              if (context.mounted) {
                Navigator.pop(context); // Remove loader
                if (product != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(
                        product: product,
                        isDiscounted: notification.type == 'offer',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product not found or deleted')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading product: $e')),
                );
              }
            }
          }
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'offer':
        return Icons.local_offer;
      case 'cart':
        return Icons.shopping_cart;
      case 'payment':
        return Icons.payment;
      case 'account':
        return Icons.person;
      case 'review':
        return Icons.star;
      case 'new_product':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'offer':
        return Colors.red;
      case 'cart':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'account':
        return Colors.purple;
      case 'review':
        return Colors.yellow.shade800;
      case 'new_product':
        return Colors.teal;
      default:
        return const Color(0xFFD88A1F);
    }
  }
}
