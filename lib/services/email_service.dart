import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // CONFIGURATION: Replace these with actual SMTP credentials.
  // For production: Use Gmail App Password or an SMTP provider like SendGrid/Mailgun.
  // For development: Use Mailtrap.io (highly recommended for testing).
  final String _username = 'renproject717@gmail.com';
  final String _password = 'sfna llmj fxha fhpf';

  Future<void> sendLowStockEmail({
    required String ownerEmail,
    required String businessName,
    required ProductModel product,
    required String type, // 'low' or 'out'
  }) async {
    final smtpServer = gmail(_username, _password);
    
    final String updateLink = 'bizease://product/edit/${product.id}';
    final String addStockLink = 'bizease://product/add-stock/${product.id}';
    final String removeLink = 'bizease://product/delete/${product.id}';

    String subject = '';
    String htmlBody = '';

    if (type == 'out') {
      subject = '❌ Out of Stock: ${product.name} – Update Required';
      htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
        <h2 style="color: #d9534f; border-bottom: 2px solid #d9534f; padding-bottom: 10px;">Out of Stock Alert</h2>
        <p>Hello <strong>$businessName</strong>,</p>
        <p>Your product "<strong>${product.name}</strong>" is now <span style="color: #d9534f; font-weight: bold;">OUT OF STOCK</span>.</p>
        <p>Customers cannot purchase it until you update the inventory.</p>
        <div style="background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
           <strong>Stock Quantity:</strong> 0
        </div>
        <p><strong>Actions:</strong></p>
        <ul style="list-style: none; padding: 0;">
          <li style="margin-bottom: 10px;">➜ <a href="$addStockLink" style="color: #0275d8; text-decoration: none; font-weight: bold;">Add new stock</a></li>
          <li style="margin-bottom: 10px;">➜ <a href="$removeLink" style="color: #d9534f; text-decoration: none; font-weight: bold;">Remove product</a></li>
        </ul>
        <br>
        <p style="font-size: 12px; color: #777;">Sent via Biz Ease Automated Inventory System</p>
      </div>
      ''';
    } else {
      subject = '⚠️ Low Stock Alert: ${product.name}';
      htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
        <h2 style="color: #f0ad4e; border-bottom: 2px solid #f0ad4e; padding-bottom: 10px;">Low Stock Alert</h2>
        <p>Hello <strong>$businessName</strong>,</p>
        <p>Your product "<strong>${product.name}</strong>" is running low.</p>
        <div style="background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
           <strong>Current Stock:</strong> ${product.stock} left
        </div>
        <p>Please update stock before it runs out.</p>
        <p><strong>Actions:</strong></p>
        <ul style="list-style: none; padding: 0;">
          <li style="margin-bottom: 10px;">➜ <a href="$updateLink" style="color: #0275d8; text-decoration: none; font-weight: bold;">Update details</a></li>
          <li style="margin-bottom: 10px;">➜ <a href="$addStockLink" style="color: #5cb85c; text-decoration: none; font-weight: bold;">Add more stock</a></li>
          <li style="margin-bottom: 10px;">➜ <a href="$removeLink" style="color: #d9534f; text-decoration: none; font-weight: bold;">Remove product</a></li>
        </ul>
        <br>
        <p style="font-size: 12px; color: #777;">Sent via Biz Ease Automated Inventory System</p>
      </div>
      ''';
    }

    final message = Message()
      ..from = Address(_username, 'Biz Ease')
      ..recipients.add(ownerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Attempting to send $type stock email to $ownerEmail...');
      if (kIsWeb) {
        await _sendViaEmailJS(ownerEmail, subject, htmlBody);
        return;
      }
      final sendReport = await send(message, smtpServer);
      debugPrint('Email sent successfully: ${sendReport.toString()}');
    } catch (e) {
      debugPrint('CRITICAL EMAIL ERROR: $e');
    }
  }

  Future<void> sendStockUpdateConfirmation({
    required String ownerEmail,
    required String businessName,
    required ProductModel product,
  }) async {
    final smtpServer = gmail(_username, _password);
    
    final subject = '✅ Stock Updated: ${product.name}';
    final htmlBody = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
      <h2 style="color: #5cb85c; border-bottom: 2px solid #5cb85c; padding-bottom: 10px;">Stock Update Confirmation</h2>
      <p>Hello <strong>$businessName</strong>,</p>
      <p>This is to confirm that the stock for "<strong>${product.name}</strong>" has been updated.</p>
      <div style="background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
         <strong>New Stock Quantity:</strong> ${product.stock}
      </div>
      <p>➜ <a href="bizease://product/view/${product.id}" style="color: #0275d8; text-decoration: none; font-weight: bold;">View Product</a></p>
      <br>
      <p style="font-size: 12px; color: #777;">Sent via Biz Ease Automated Inventory System</p>
    </div>
    ''';

    final message = Message()
      ..from = Address(_username, 'Biz Ease')
      ..recipients.add(ownerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Attempting to send stock update confirmation to $ownerEmail...');
      if (kIsWeb) {
        await _sendViaEmailJS(ownerEmail, subject, htmlBody);
        return;
      }
      final sendReport = await send(message, smtpServer);
      debugPrint('Update confirmation sent: ${sendReport.toString()}');
    } catch (e) {
      debugPrint('CRITICAL UPDATE EMAIL ERROR: $e');
    }
  }

  Future<void> sendNewProductConfirmation({
    required String ownerEmail,
    required String businessName,
    required ProductModel product,
  }) async {
    final smtpServer = gmail(_username, _password);
    
    final subject = '🆕 New Product Added: ${product.name}';
    final htmlBody = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
      <h2 style="color: #0275d8; border-bottom: 2px solid #0275d8; padding-bottom: 10px;">New Product Added</h2>
      <p>Hello <strong>$businessName</strong>,</p>
      <p>Your new product "<strong>${product.name}</strong>" has been successfully listed.</p>
      <div style="background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
         <strong>Initial Stock:</strong> ${product.stock}
      </div>
      <p>➜ <a href="bizease://product/view/${product.id}" style="color: #0275d8; text-decoration: none; font-weight: bold;">View in Shop</a></p>
      <br>
      <p style="font-size: 12px; color: #777;">Sent via Biz Ease Automated Inventory System</p>
    </div>
    ''';

    final message = Message()
      ..from = Address(_username, 'Biz Ease')
      ..recipients.add(ownerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Attempting to send new product confirmation to $ownerEmail...');
      if (kIsWeb) {
        await _sendViaEmailJS(ownerEmail, subject, htmlBody);
        return;
      }
      final sendReport = await send(message, smtpServer);
      debugPrint('New product confirmation sent: ${sendReport.toString()}');
    } catch (e) {
      debugPrint('CRITICAL NEW PRODUCT EMAIL ERROR: $e');
    }
  }

  Future<void> sendOrderConfirmation(OrderModel order) async {
    final smtpServer = gmail(_username, _password);
    
    final subject = '🛍️ Order Confirmed: #${order.id.substring(0, 8)}';
    
    String itemsHtml = '';
    for (var item in order.items) {
      itemsHtml += '''
        <tr>
          <td style="padding: 10px; border-bottom: 1px solid #eee;">${item.name} x ${item.quantity}</td>
          <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">${(item.numericPrice * item.quantity).toStringAsFixed(2)}</td>
        </tr>
      ''';
    }

    final htmlBody = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
      <h2 style="color: #0275d8; border-bottom: 2px solid #0275d8; padding-bottom: 10px;">Order Confirmation</h2>
      <p>Hello <strong>${order.customerName}</strong>,</p>
      <p>Thank you for shopping with us! Your order has been successfully placed.</p>
      
      <div style="background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <h4 style="margin-top: 0;">Order Details:</h4>
        <table style="width: 100%; border-collapse: collapse;">
          ${itemsHtml}
          <tr>
            <td style="padding: 10px; font-weight: bold;">Total Amount</td>
            <td style="padding: 10px; font-weight: bold; text-align: right;">${order.totalAmount.toStringAsFixed(2)}</td>
          </tr>
        </table>
      </div>

      <p><strong>Shipping to:</strong><br>${order.deliveryAddress ?? 'N/A'}</p>
      
      <p>We will notify you as soon as your order status changes.</p>
      <br>
      <p style="font-size: 12px; color: #777;">Sent via Biz Ease / Ren Project</p>
    </div>
    ''';

    final message = Message()
      ..from = Address(_username, 'Biz Ease')
      ..recipients.add(order.customerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Sending order confirmation to ${order.customerEmail}...');
      if (kIsWeb) {
        await _sendViaEmailJS(order.customerEmail, subject, htmlBody);
        return;
      }
      await send(message, smtpServer);
      debugPrint('Order confirmation sent.');
    } catch (e) {
      debugPrint('CRITICAL ORDER EMAIL ERROR: \$e');
    }
  }

  Future<void> sendOrderStatusUpdate(OrderModel order) async {
    final smtpServer = gmail(_username, _password);
    
    final subject = '🚚 Order Status Updated: ${order.statusText}';
    final statusColor = order.status == OrderStatus.delivered ? '#5cb85c' : '#0275d8';

    final htmlBody = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
      <h2 style="color: $statusColor; border-bottom: 2px solid $statusColor; padding-bottom: 10px;">Order Status Update</h2>
      <p>Hello <strong>${order.customerName}</strong>,</p>
      <p>The status of your order <strong>#${order.id.substring(0, 8)}</strong> has been updated to:</p>
      
      <div style="background: #f9f9f9; padding: 20px; border-radius: 5px; text-align: center; margin: 20px 0;">
        <span style="font-size: 24px; font-weight: bold; color: $statusColor;">${order.statusText.toUpperCase()}</span>
      </div>

      <p>Thank you for your patience!</p>
      <br>
      <p style="font-size: 12px; color: #777;">Sent via Biz Ease / Ren Project</p>
    </div>
    ''';

    final message = Message()
      ..from = Address(_username, 'Biz Ease')
      ..recipients.add(order.customerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Sending status update to ${order.customerEmail}...');
      if (kIsWeb) {
        await _sendViaEmailJS(order.customerEmail, subject, htmlBody);
        return;
      }
      await send(message, smtpServer);
      debugPrint('Status update sent.');
    } catch (e) {
      debugPrint('CRITICAL STATUS EMAIL ERROR: \$e');
    }
  }

  // Fallback for Web: Send via EmailJS (100% Free, No Credit Card needed)
  Future<void> _sendViaEmailJS(String to, String subject, String html) async {
    debugPrint('STEP 1: Triggering EmailJS for recipient: $to');
    
    const String serviceId = 'service_2a635vr';
    const String templateId = 'template_8opoye8';
    const String publicKey = 'hylY4z0kXxpxUi4pC';

    if (to.isEmpty) {
      debugPrint('ERROR: Recipient email (to) is empty! Check owner data.');
      return;
    }

    try {
      final payload = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': to,
          'subject': subject,
          'message_html': html,
        },
      };
      
      debugPrint('STEP 2: Data prepared. Sending request to EmailJS API...');

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('STEP 3: Response received from EmailJS.');

      if (response.statusCode == 200) {
        debugPrint('✅ SUCCESS: Email sent successfully via EmailJS!');
      } else {
        debugPrint('❌ FAILED: EmailJS returned status \${response.statusCode}');
        debugPrint('ERROR BODY: \${response.body}');
        
        if (response.body.contains('user_id is required')) {
          debugPrint('HINT: Your Public Key might be missing or incorrect.');
        } else if (response.body.contains('template_id is required')) {
          debugPrint('HINT: Your Template ID might be incorrect.');
        }
      }
    } catch (e) {
      debugPrint('❌ CRITICAL ERROR during EmailJS call: $e');
    }
  }

  Future<void> sendMfaCode({
    required String ownerEmail,
    required String code,
  }) async {
    final smtpServer = gmail(_username, _password);
    
    final subject = '🔒 BizEase Security: Your Login Code';
    final htmlBody = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
      <h2 style="color: #D88A1F; border-bottom: 2px solid #D88A1F; padding-bottom: 10px;">Secure Login</h2>
      <p>Hello,</p>
      <p>A sign-in attempt was made to your BizEase Business account. Please use the following code to complete the process:</p>
      <div style="background: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center;">
         <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #D88A1F;">$code</span>
      </div>
      <p>If you did not attempt to sign in, please ignore this email and consider updating your password.</p>
      <br>
      <p style="font-size: 12px; color: #777;">BizEase Security System</p>
    </div>
    ''';

    final message = Message()
      ..from = Address(_username, 'Biz Ease Security')
      ..recipients.add(ownerEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      debugPrint('Attempting to send MFA code to $ownerEmail...');
      if (kIsWeb) {
        await _sendViaEmailJS(ownerEmail, subject, htmlBody);
        return;
      }
      final sendReport = await send(message, smtpServer);
      debugPrint('MFA Code sent successfully: ${sendReport.toString()}');
    } catch (e) {
      debugPrint('CRITICAL MFA EMAIL ERROR: $e');
    }
  }

  // Previous Firestore fallback (kept for reference or secondary backup)
  Future<void> _sendViaFirestore(String to, String subject, String html) async {
    try {
      await _firestore.collection('mail').add({
        'to': to,
        'message': {
          'subject': subject,
          'html': html,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Web: Email request queued in Firestore "mail" collection.');
    } catch (e) {
      debugPrint('Error queuing email in Firestore: $e');
    }
  }
}
