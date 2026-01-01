import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'home_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class OrderPlacedPage extends StatelessWidget {
  final String orderNumber;
  final double totalAmount;
  final String paymentMethod;

  const OrderPlacedPage({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFD88A1F);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Constant shipping for now
    final double shipping = 200.0;
    final double subtotal = totalAmount - shipping;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade100, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Thank you for your purchase. Your order has been confirmed.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Order Details Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildDetailRow('Order Number', orderNumber),
                          const Divider(height: 24),
                          _buildDetailRow('Payment Method', paymentMethod),
                          const Divider(height: 24),
                          _buildDetailRow('Subtotal', 'Rs. ${_formatPrice(subtotal)}'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Shipping', 'Rs. ${_formatPrice(shipping)}'),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Total Amount',
                            'Rs. ${_formatPrice(totalAmount)}',
                            isTotal: true,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Estimated Delivery',
                            '3-5 Business Days',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            cartProvider.clearCart();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue Shopping',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _downloadReceipt(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: primaryColor),
                          ),
                          child: Text(
                            'Download Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFFD88A1F) : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } else {
      return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(\.|$))'),
        (Match m) => '${m[1]},',
      );
    }
  }

  void _downloadReceipt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Receipt'),
        content: const Text('Choose how you want to save your receipt:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyReceiptToClipboard(context);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 16),
                SizedBox(width: 8),
                Text('Copy to Clipboard'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareReceipt(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD88A1F),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share, size: 16),
                SizedBox(width: 8),
                Text('Share Receipt'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadPDFReceipt(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD88A1F),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, size: 16),
                SizedBox(width: 8),
                Text('Download PDF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyReceiptToClipboard(BuildContext context) {
    final receiptText = _generateReceiptText();
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    final receiptText = _generateReceiptText();
    Share.share(
      receiptText,
      subject: 'BizEase Receipt - $orderNumber',
    );
  }

  String _generateReceiptText() {
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    
    final shipping = 200.0;
    final subtotal = totalAmount - shipping;
    
    return '''
╔══════════════════════════════════════════╗
║            BIZEASE - RECEIPT             ║
╚══════════════════════════════════════════╝

ORDER DETAILS
─────────────
Order Number:  $orderNumber
Date:          $formattedDate
Time:          $formattedTime
Payment Method: $paymentMethod

AMOUNT DETAILS
─────────────
Subtotal:      Rs. ${_formatPrice(subtotal)}
Shipping:      Rs. ${_formatPrice(shipping)}
─────────────
TOTAL:         Rs. ${_formatPrice(totalAmount)}

──────────────────────────────────────────
Thank you for shopping with BizEase!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  Future<void> _downloadPDFReceipt(BuildContext context) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    
    final shipping = 200.0;
    final subtotal = totalAmount - shipping;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('BIZEASE - RECEIPT',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('ORDER DETAILS',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Order Number:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(orderNumber),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date:'),
                      pw.Text(formattedDate),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Time:'),
                      pw.Text(formattedTime),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Payment Method:'),
                      pw.Text(paymentMethod),
                    ]),
                pw.SizedBox(height: 30),
                pw.Text('AMOUNT DETAILS',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:'),
                      pw.Text('Rs. ${_formatPrice(subtotal)}'),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Shipping:'),
                      pw.Text('Rs. ${_formatPrice(shipping)}'),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL:',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs. ${_formatPrice(totalAmount)}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange)),
                    ]),
                pw.SizedBox(height: 50),
                pw.Center(
                  child: pw.Text('Thank you for shopping with BizEase!',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                ),
              ],
            ),
          );
        },
      ),
    );

    // This will open the print/save dialog which allows saving as PDF on modern systems
    final bytes = await pdf.save();

    try {
      if (kIsWeb) {
        // On Web, layoutPdf opens the browser's print preview which can "Save as PDF"
        await Printing.layoutPdf(
          onLayout: (format) => bytes,
          name: 'BizEase-Receipt-$orderNumber.pdf',
        );
      } else {
        // On Desktop/Mobile, try to save to a file or share
        try {
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            final filePath = '${directory.path}/BizEase-Receipt-$orderNumber.pdf';
            final file = File(filePath);
            await file.writeAsBytes(bytes);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt saved to: $filePath'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('Error saving to downloads: $e');
        }

        // Fallback to sharing if direct save fails or directory is null
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'BizEase-Receipt-$orderNumber.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
