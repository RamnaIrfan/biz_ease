import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'communication_service.dart';
import '../api_key.dart';
import '../models/order_model.dart';

class SupportAgentService {
  late final GenerativeModel _model;
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  
  final List<Content> _chatHistory = [];

  SupportAgentService() {
    // Define the tools (functions) the AI can call
    final tools = [
      Tool(functionDeclarations: [
        FunctionDeclaration(
          'check_order_status',
          'Get the current status and details of a customer order.',
          Schema.object(properties: {
            'orderId': Schema.string(description: 'The unique ID of the order.'),
          }, requiredProperties: ['orderId']),
        ),
        FunctionDeclaration(
          'cancel_order',
          'Attempt to cancel an order. Only possible if the order status is "pending".',
          Schema.object(properties: {
            'orderId': Schema.string(description: 'The unique ID of the order to cancel.'),
          }, requiredProperties: ['orderId']),
        ),
        FunctionDeclaration(
          'search_products',
          'Search for products in the catalog based on a text query (name or category).',
          Schema.object(properties: {
            'query': Schema.string(description: 'The search term (e.g., "red watch", "electronics").'),
          }, requiredProperties: ['query']),
        ),
        FunctionDeclaration(
          'send_whatsapp_message',
          'Send a formal WhatsApp message to the customer. Useful for sending order details or important updates.',
          Schema.object(properties: {
            'phoneNumber': Schema.string(description: 'The customer\'s phone number with country code (e.g., "923001234567").'),
            'message': Schema.string(description: 'The content of the WhatsApp message.'),
          }, requiredProperties: ['phoneNumber', 'message']),
        ),
      ])
    ];

    _model = GenerativeModel(
      model: 'gemini-flash-lite-latest',
      apiKey: APIKey.key,
      tools: tools,
      systemInstruction: Content.system('''
        You are the BizEase Support Agent. Your goal is to help customers with their orders and product questions.
        You have access to tools to check order status, cancel orders, and search products.
        Always be polite, professional, and helpful.
        If you cancel an order, confirm it was successful or explain why it failed.
        If a customer asks about products, use search_products to find relevant items.
        
        SHIPPING POLICY:
        - Shipping is FREE for all orders of Rs. 3000 or above!
        - For orders under Rs. 3000, there is a flat shipping charge of Rs. 200.
        Always explain this shipping policy clearly if a customer asks about delivery charges, shipping costs, or checkout totals.
      '''),
    );
  }

  Future<String> sendMessage(String message) async {
    final userContent = Content.text(message);
    
    try {
      // 1. Prepare history for the request
      final List<Content> requestHistory = [..._chatHistory, userContent];
      
      // 2. Initial request to the model
      var response = await _model.generateContent(requestHistory);
      
      // 3. Handle potential function calls in a loop
      while (response.candidates.first.content.parts.any((p) => p is FunctionCall)) {
        final content = response.candidates.first.content;
        
        // SDK HACK: The google_generative_ai (0.4.7) strips `thought_signature` from FunctionCall parts.
        // Sending it back without the signature causes Gemini 3 to throw a 400 Error.
        // Workaround: We document the tool call and result as text conversational turns instead.
        String toolResultsString = "SYSTEM: You executed the following tools:\n";
        
        for (final part in content.parts) {
          if (part is FunctionCall) {
            debugPrint('Agent requested tool: ${part.name} with args: ${part.args}');
            
            Object result;
            if (part.name == 'check_order_status') {
              final order = await _orderService.getOrder(part.args['orderId'] as String);
              result = order != null ? order.toMap() : {'error': 'Order not found'};
            } else if (part.name == 'cancel_order') {
              try {
                final order = await _orderService.getOrder(part.args['orderId'] as String);
                if (order == null) {
                  result = {'success': false, 'message': 'Order not found'};
                } else if (order.status != OrderStatus.pending) {
                  result = {'success': false, 'message': 'Order cannot be cancelled as it is already ${order.statusText}'};
                } else {
                  await _orderService.cancelOrder(part.args['orderId'] as String);
                  result = {'success': true, 'message': 'Order cancelled successfully'};
                }
              } catch (e) {
                result = {'success': false, 'message': e.toString()};
              }
            } else if (part.name == 'search_products') {
              final products = await _productService.searchProducts(part.args['query'] as String).first;
              result = products.map((p) => p.toMap()).toList();
            } else if (part.name == 'send_whatsapp_message') {
              try {
                await CommunicationService().sendGeneralWhatsAppMessage(
                  phoneNumber: part.args['phoneNumber'] as String,
                  message: part.args['message'] as String,
                );
                result = {'success': true, 'message': 'WhatsApp message sent successfully'};
              } catch (e) {
                result = {'success': false, 'message': e.toString()};
              }
            } else {
              result = {'error': 'Unknown tool'};
            }
            
            toolResultsString += "- Tool '${part.name}' with args ${part.args} returned:\n${jsonEncode(_cleanData(result))}\n\n";
          }
        }
        
        // Add the proxy turns to history instead of the broken FunctionCall/FunctionResponse objects
        requestHistory.add(Content.model([TextPart("I am requesting external data using my tools...")]));
        requestHistory.add(Content.text(toolResultsString));
        
        // Send the updated conversation back to the model
        response = await _model.generateContent(requestHistory);
      }
      
      final responseText = response.text ?? "I'm sorry, I encountered an issue processing that.";
      
      // Update persistent chat history for future messages
      _chatHistory.add(userContent);
      _chatHistory.add(response.candidates.first.content);
      
      return responseText;
      
    } catch (e) {
      debugPrint('🚨 Support Agent Error: $e');
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ Quota Exceeded: My API key has hit its daily limit! To wake me back up, the developer needs to provide a new API key from Google AI Studio.";
      }
      if (e.toString().contains('model not found')) {
        return "The AI system is being updated. Please try again in a few minutes.";
      }
      return "I'm having trouble connecting to my systems ($e). Please try again in a moment.";
    }
  }

  /// 🧹 CLEAN DATA FOR AI
  /// Converts Firestore Timestamps and other non-JSON types into strings
  dynamic _cleanData(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), _cleanData(v)));
    } else if (data is List) {
      return data.map((e) => _cleanData(e)).toList();
    } else if (data is DateTime) {
      return data.toIso8601String();
    } else if (data.runtimeType.toString().contains('Timestamp')) {
      // Handles Firestore Timestamp without needing the import everywhere
      try {
        return (data as dynamic).toDate().toIso8601String();
      } catch (_) {
        return data.toString();
      }
    }
    return data;
  }

  List<Content> get history => _chatHistory;
}
