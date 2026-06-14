# 📢 2. Marketing Hub Agent Documentation

## 📂 File Location
`lib/services/marketing_agent_service.dart` (relies on `lib/services/ai_service.dart`)

## 🎯 What it does
The **Marketing Agent** automates the creation and publishing of social media campaigns for Business Owners. Instead of a business owner having to manually design a post, write a caption, research hashtags, and draft video scripts for different platforms, they simply select a product from their inventory. The agent autonomously acts as a Social Media Manager, tailoring the content specifically for the unique algorithms of Instagram, Facebook, and TikTok simultaneously.

## ⚙️ How it works (Functionality)
This agent utilizes **Gemini's Multimodal (Vision + Text) capabilities** and **Structured JSON Output**.
1. **Multimodal Analysis:** The agent takes the user's selected product data (Name, Price, Description) AND physically downloads the Product Image from Firebase Storage. It feeds both the image and the text to the AI simultaneously.
2. **Structured Generation:** The AI is strictly prompted to return its response in a perfect JSON format. This allows the app to parse the response into UI elements (showing the Instagram caption in one tab, and the TikTok script in another).
3. **Execution (Publishing):** Once the owner approves the AI's generated campaign, the agent triggers the device's native Share Sheet to physically post the content to the selected social media apps, and triggers a webhook for analytics logging.

## 💻 Full Code Explanation

```dart
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

  // 1. GENERATE CAMPAIGN METHOD
  Future<Map<String, dynamic>> generateAndReviewCampaign({
    required ProductModel product,
    required String instructions,
    required List<String> platforms,
  }) async {
    try {
      Uint8List? imageBytes;
      
      // Step A: Fetch the actual Image Bytes from the internet
      // The AI needs raw bytes to "see" the image.
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

      // Step B: Pass the product data, instructions, and image to the core AI Service
      final campaign = await _aiService.generateFullMarketingCampaign(
        product: product,
        userInstructions: instructions,
        platforms: platforms,
        productImageBytes: imageBytes, // Multimodal vision input
      );

      return campaign;
    } catch (e) {
      throw 'Marketing Agent encountered an error: $e';
    }
  }

  // 2. PUBLISH CAMPAIGN METHOD
  Future<void> postCampaign({
    required ProductModel product,
    required Map<String, dynamic> campaignData,
    required List<String> platforms,
  }) async {
    
    // Step A: Construct the final text that will be shared.
    String shareText = '🚀 NEW ARRIVAL: \${product.name}\\n\\n';
    
    // Dynamically grab the caption from the JSON data for the primary platform
    final firstPlatform = platforms.isNotEmpty ? platforms.first.toLowerCase() : 'instagram';
    final data = campaignData[firstPlatform] ?? {};
    
    shareText += '\${data['caption'] ?? data['post_content'] ?? data['video_script'] ?? ''}\\n\\n';
    
    // Step B: Append deep-links so customers can buy the product directly
    shareText += '🔗 SHOP NOW: https://bizease.app/product/\${product.id}\\n';
    shareText += '🛒 Check out our full store at: https://bizease.app\\n';
    if (data['hashtags'] != null) shareText += '\\n\${data['hashtags']}';

    // Step C: Trigger the native Android/iOS Share Sheet
    await Share.share(
      shareText,
      subject: 'Check out our new \${product.name}!',
    );

    // Step D: Log the action to an external webhook for business analytics
    final payload = {
      'productId': product.id,
      'productName': product.name,
      'platforms': platforms,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _commService.postToSocialMediaWebhook(payload);
  }
}
```

### The Core AI Generation Logic (Found in `ai_service.dart`)
```dart
  Future<Map<String, dynamic>> generateFullMarketingCampaign(...) async {
    // 1. PROMPT ENGINEERING
    // We enforce a strict JSON schema so the Flutter app doesn't crash when reading the response.
    final prompt = '''
    Act as a professional Social Media Marketing Agency. Create a full marketing campaign...
    Please provide the response in a STRICT JSON format. 
    If Instagram is selected, include: "instagram": { "caption": "...", "hashtags": "..." }
    If TikTok is selected, include: "tiktok": { "video_script": "...", "hook": "..." }
    ''';

    // 2. MULTIMODAL INJECTION
    final List<Content> content = [];
    if (productImageBytes != null) {
      // If an image exists, we send BOTH text and the jpeg image.
      content.add(Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', productImageBytes),
      ]));
    } else {
      content.add(Content.text(prompt));
    }

    final response = await _model.generateContent(content);
    
    // 3. JSON PARSING & CLEANUP
    // The AI sometimes wraps JSON in ```json blocks. This code cleans those blocks out
    // so `json.decode()` can successfully convert the string into a Dart Map.
    String cleanedText = response.text!.trim();
    if (cleanedText.startsWith('```json')) { ... }
    
    return json.decode(cleanedText) as Map<String, dynamic>;
  }
```
