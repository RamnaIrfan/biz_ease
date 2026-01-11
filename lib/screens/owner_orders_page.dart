import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../screens/auth_provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class OwnerOrdersPage extends StatelessWidget {
  const OwnerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ownerId = auth.userId;
    final primaryColor = const Color(0xFFD88A1F);

    if (ownerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Manage Orders")),
        body: const Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Orders"),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getOwnerOrders(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderManagementCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderManagementCard extends StatelessWidget {
  final OrderModel order;
  const _OrderManagementCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD88A1F).withAlpha((0.1 * 255).toInt()),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Customer: ${order.customerName}", style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                      Text(item.price, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormat.format(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Update Status:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: OrderStatus.values.map((status) {
                      final isCurrent = order.status == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: isCurrent ? Colors.white : Colors.black)),
                          selected: isCurrent,
                          selectedColor: const Color(0xFFD88A1F),
                          onSelected: (selected) {
                            if (selected && !isCurrent) {
                              OrderService().updateOrderStatus(order.id, status).then((_) {
                                // Trigger notification for customer
                                NotificationService().createNotification(
                                  userId: order.customerId,
                                  title: 'Order Status Updated',
                                  message: 'Order #${order.id.substring(0, 8)} is now ${status.name.toUpperCase()}',
                                  type: 'order',
                                );
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.processing: color = Colors.blue; break;
      case OrderStatus.confirmed: color = Colors.indigo; break;
      case OrderStatus.shipped: color = Colors.purple; break;
      case OrderStatus.delivered: color = Colors.green; break;
      case OrderStatus.cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
