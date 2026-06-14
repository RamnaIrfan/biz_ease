import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import 'ai_service.dart';
import 'communication_service.dart';

class MarketingAgentService {
  final AIService _aiService = AIService();
  final CommunicationService _commService = CommunicationService();

  /// The main agent function: Analyzes, Designs, and Posts.
  Future<Map<String, dynamic>> generateAndReviewCampaign({
    required ProductModel product,
    required String instructions,
    required List<String> platforms,
  }) async {
    try {
      Uint8List? imageBytes;
      
      // 1. Fetch product image if it exists
      if (product.imageUrl != null && product.imageUrl!.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(product.imageUrl!));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Agent failed to fetch image: $e');
        }
      }

      // 2. Generate the full campaign using AI Vision + Text
      final campaign = await _aiService.generateFullMarketingCampaign(
        product: product,
        userInstructions: instructions,
        platforms: platforms,
        productImageBytes: imageBytes,
      );

      return campaign;
    } catch (e) {
      throw 'Marketing Agent encountered an error: $e';
    }
  }

  /// Finalize and share the approved campaign
  Future<void> postCampaign({
    required ProductModel product,
    required Map<String, dynamic> campaignData,
    required List<String> platforms,
  }) async {
    // 1. Build the master sharing text
    String shareText = '🚀 NEW ARRIVAL: ${product.name}\n\n';
    
    // Use the first available platform's caption as the lead
    final firstPlatform = platforms.isNotEmpty ? platforms.first.toLowerCase() : 'instagram';
    final data = campaignData[firstPlatform] ?? {};
    
    shareText += '${data['caption'] ?? data['post_content'] ?? data['video_script'] ?? ''}\n\n';
    // Add the specific Shop Link (Works for Instagram, Facebook, and TikTok)
    shareText += '🔗 SHOP NOW: https://bizease.app/product/${product.id}\n';
    shareText += '🛒 Check out our full store at: https://bizease.app\n';
    if (data['hashtags'] != null) shareText += '\n${data['hashtags']}';

    // 2. Trigger System Share Sheet
    // ignore: deprecated_member_use
    await Share.share(
      shareText,
      subject: 'Check out our new ${product.name}!',
    );

    // 3. Log to webhook (for analytics/records)
    final payload = {
      'productId': product.id,
      'productName': product.name,
      'platforms': platforms,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _commService.postToSocialMediaWebhook(payload);
  }

  /// Download / Export the campaign (Image + Text)
  Future<void> downloadCampaign({
    required ProductModel product,
    required Map<String, dynamic> campaignData,
    required String platform,
  }) async {
    try {
      // 1. Build the text content
      final data = campaignData[platform.toLowerCase()] ?? {};
      String shareText = '🚀 NEW ARRIVAL: ${product.name}\n\n';
      shareText += '${data['caption'] ?? data['post_content'] ?? data['video_script'] ?? ''}\n\n';
      if (data['hashtags'] != null) shareText += '\n${data['hashtags']}';

      // 2. Fetch and save the image to a temporary file
      List<XFile> filesToShare = [];
      if (product.imageUrl != null && product.imageUrl!.startsWith('http')) {
        final response = await http.get(Uri.parse(product.imageUrl!));
        if (response.statusCode == 200) {
          filesToShare.add(
            XFile.fromData(
              response.bodyBytes,
              name: '${product.id}_post.jpg',
              mimeType: 'image/jpeg',
            ),
          );
        }
      }

      // 3. Share text and image natively
      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(
          filesToShare,
          text: shareText,
          subject: 'Marketing Post for ${product.name}',
        );
      } else {
        // Fallback if no image
        // ignore: deprecated_member_use
        await Share.share(
          shareText,
          subject: 'Marketing Post for ${product.name}',
        );
      }
    } catch (e) {
      throw 'Failed to download post: $e';
    }
  }
}
