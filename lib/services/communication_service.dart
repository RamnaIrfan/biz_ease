import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationService {
  // IMPORTANT: Replace these with your actual EmailJS credentials from https://www.emailjs.com/
  static const String _serviceId = 'service_2a635vr';
  static const String _templateId = 'template_8opoye8';
  static const String _userId = 'hylY4z0kXxpxUi4pC'; // Usually called Public Key now

  /// Sends an order confirmation email using EmailJS API
  Future<void> sendOrderConfirmationEmail({
    required String customerName,
    required String customerEmail,
    required String orderNumber,
    required double totalAmount,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _userId,
        'template_params': {
          'to_name': customerName,
          'to_email': customerEmail,
          'order_number': orderNumber,
          'total_amount': totalAmount.toStringAsFixed(2),
          'message': 'Thank you for your order! Your order $orderNumber has been placed successfully and will be processed soon.',
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  /// Opens WhatsApp with a pre-filled confirmation message (Fallback/Manual)
  Future<void> sendWhatsAppConfirmation({
    required String phoneNumber,
    required String orderNumber,
    required double totalAmount,
  }) async {
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!formattedNumber.startsWith('92') && formattedNumber.length == 10 && formattedNumber.startsWith('3')) {
      formattedNumber = '92$formattedNumber';
    } else if (formattedNumber.startsWith('03')) {
      formattedNumber = '92${formattedNumber.substring(1)}';
    }
    
    final message = 'Hello! Your order $orderNumber for Rs. ${totalAmount.toStringAsFixed(2)} is confirmed. Thank you for shopping with biZEase!';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$formattedNumber?text=$encodedMessage');
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp. Please make sure WhatsApp is installed.');
    }
  }

  /// 🤖 AUTOMATED WHATSAPP NOTIFICATION (Cloud Functions)
  /// Sends a professional message with buttons via Twilio
  Future<void> sendAutomatedWhatsAppOrder({
    required String orderId,
    required String phoneNumber,
    required String customerName,
    required double totalAmount,
    required List<dynamic> items,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendWhatsAppOrder');
      
      await callable.call({
        'orderId': orderId,
        'phoneNumber': phoneNumber,
        'customerName': customerName,
        'totalAmount': totalAmount,
        'items': items.map((item) => {
          'name': item.name,
          'quantity': item.quantity,
        }).toList(),
      });
    } catch (e) {
      print('WhatsApp Automation Error: $e');
      // Re-throw if critical, or ignore if we want the manual fallback to take over
      rethrow;
    }
  }

  /// 🤖 GENERAL WHATSAPP MESSAGE (Cloud Functions)
  /// Allows the AI to send custom text to a customer
  Future<void> sendGeneralWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendWhatsAppOrder'); // Reusing the same logic for simplicity
      
      await callable.call({
        'phoneNumber': phoneNumber,
        'customMessage': message, // We'll update the Cloud Function to handle this
      });
    } catch (e) {
      print('WhatsApp General Error: $e');
      rethrow;
    }
  }

  /// Sends AI-generated marketing content to a social media webhook
  /// (e.g., Make.com, Zapier, or a custom backend)
  Future<void> postToSocialMediaWebhook(Map<String, dynamic> marketingData) async {
    // IMPORTANT: Replace this with your actual marketing webhook URL
    // For now, using a placeholder to demonstrate the flow.
    const String webhookUrl = 'https://hook.us1.make.com/placeholder_webhook_id';
    
    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(marketingData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Social media service returned error: ${response.body}');
      }
    } catch (e) {
      // Re-throw to be handled by the UI
      rethrow;
    }
  }
}
