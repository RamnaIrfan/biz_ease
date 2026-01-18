import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/ai_service.dart';

class BusinessInsightsCard extends StatefulWidget {
  final List<OrderModel> orders;

  const BusinessInsightsCard({super.key, required this.orders});

  @override
  State<BusinessInsightsCard> createState() => _BusinessInsightsCardState();
}

class _BusinessInsightsCardState extends State<BusinessInsightsCard> {
  String? _insights;
  bool _isGenerating = false;
  bool _hasGenerated = false;

  void _generateInsights() async {
    setState(() => _isGenerating = true);

    // Prepare data summary
    final totalOrders = widget.orders.length;
    final totalRevenue = widget.orders.fold(0.0, (sum, order) => sum + order.totalPrice);
    final completedOrders = widget.orders.where((o) => o.status == OrderStatus.delivered).length;
    
    // Simple top products analysis (if order items were easily accessible in a flat list, simplifying for now)
    // We will send a high level summary
    final summary = "Total Orders: $totalOrders. Total Revenue: $totalRevenue. Completed Orders: $completedOrders. "
        "Recent orders status: ${widget.orders.take(5).map((o) => o.statusText).join(', ')}.";

    final aiService = AIService();
    
    try {
      final result = await aiService.generateBusinessInsights(summary);

      if (mounted) {
        setState(() {
          _insights = result;
          _isGenerating = false;
          _hasGenerated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasGenerated = true;
          _insights = "Error: ${e.toString().replaceAll('GenerativeAIException: ', '')}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'AI Business Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_hasGenerated)
            Center(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateInsights,
                icon: _isGenerating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Analyzing...' : 'Generate Insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else if (_insights != null)
            Text(
              _insights!,
              style: const TextStyle(fontSize: 15, height: 1.4),
            )
          else
            const Text(
              'Failed to generate insights.',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
