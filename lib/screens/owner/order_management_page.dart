import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/communication_service.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final OrderService _orderService = OrderService();
  final CommunicationService _commService = CommunicationService();
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFD88A1F);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: orange,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (context) => [
              'All',
              'pending',
              'confirmed',
              'processing',
              'shipped',
              'delivered',
              'cancelled',
            ].map((s) => PopupMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          final filteredOrders = _statusFilter == 'All'
              ? orders
              : orders.where((o) => o.status.name == _statusFilter).toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No orders found', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withAlpha(40),
          child: Icon(Icons.shopping_bag_outlined, color: _getStatusColor(order.status)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Order #${order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusBadge(order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(dateFormat.format(order.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(item.name)),
                      Text('Rs. ${item.totalPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _resendWhatsApp(order),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Resend WhatsApp'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showStatusUpdateDialog(order),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD88A1F)),
                        child: const Text('Update Status'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.pending_confirmation: return Colors.deepOrange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.processing: return Colors.purple;
      case OrderStatus.shipped: return Colors.indigo;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  void _resendWhatsApp(OrderModel order) async {
    if (order.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided for this order')),
      );
      return;
    }

    try {
      await _commService.sendWhatsAppConfirmation(
        phoneNumber: order.phoneNumber!,
        orderNumber: order.id,
        totalAmount: order.totalAmount,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showStatusUpdateDialog(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderStatus.values.map((status) => ActionChip(
                  label: Text(status.name.toUpperCase()),
                  backgroundColor: _getStatusColor(status).withAlpha(40),
                  onPressed: () {
                    _orderService.updateOrderStatus(order.id, status);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
