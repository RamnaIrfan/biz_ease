import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_key.dart';
import '../models/product_model.dart';

class AIService {
  late final GenerativeModel _model;
  
  AIService() {
    _model = GenerativeModel(
      model: 'gemini-flash-lite-latest',
      apiKey: APIKey.key,
    );
  }

  Future<String?> generateProductDescription(String productName, String keywords) async {
    try {
      final prompt = 'Write a compelling product description for "$productName". Keywords: $keywords. Keep it concise, engaging, and suitable for an e-commerce app.';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ API Quota Exceeded: You have either hit the 5/min limit or exhausted your entire Daily Free Tier allowance. Please check Google AI Studio or use a new API key.";
      }
      return "⚠️ Error generating description.";
    }
  }

  Future<String?> generateMarketingCaption(String productName, String description, String platform) async {
    try {
      final prompt = 'Create a catchy social media caption for "$productName" on $platform. Description: $description. Include hashtags.';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ API Quota Exceeded: You have either hit the 5/min limit or exhausted your entire Daily Free Tier allowance. Please check Google AI Studio or use a new API key.";
      }
      return "⚠️ Error generating caption.";
    }
  }

  /// Generates a full marketing campaign for multiple platforms based on product data and user instructions.
  /// This is the core of the "Agentic Marketing" feature.
  Future<Map<String, dynamic>> generateFullMarketingCampaign({
    required ProductModel product,
    required String userInstructions,
    required List<String> platforms,
    Uint8List? productImageBytes,
  }) async {
    final String platformList = platforms.join(', ');
    final prompt = '''
    Act as a professional Social Media Marketing Agency. Create a full marketing campaign for the following product:
    - Name: ${product.name}
    - Category: ${product.category}
    - Price: Rs. ${product.price}
    - Description: ${product.description}
    
    Target Platforms: $platformList
    User Special Instructions: "$userInstructions"
    
    Please provide the response in a STRICT JSON format. ONLY include keys for the platforms selected.
    If Instagram is selected, include: "instagram": { "caption": "...", "hashtags": "...", "design_prompt": "Detailed description of how the marketing image should look" }
    If Facebook is selected, include: "facebook": { "post_content": "...", "design_prompt": "Detailed description of how the marketing image should look" }
    If TikTok is selected, include: "tiktok": { "video_script": "A 15-30 second script", "hook": "The opening line" }
    
    Include a "general_ad_concept": "The core theme"
    
    If an image is provided, analyze it to ensure the design prompts match the product visuals.
    ''';

    final List<Content> content = [];
    if (productImageBytes != null) {
      content.add(Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', productImageBytes),
      ]));
    } else {
      content.add(Content.text(prompt));
    }

    final response = await _model.generateContent(content);
    final responseText = response.text ?? '{}';
    
    // Clean up the response text if it contains markdown code blocks
    String cleanedText = responseText.trim();
    if (cleanedText.startsWith('```json')) {
      cleanedText = cleanedText.substring(7, cleanedText.length - 3).trim();
    } else if (cleanedText.startsWith('```')) {
      cleanedText = cleanedText.substring(3, cleanedText.length - 3).trim();
    }

    try {
      return json.decode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      return {
        'error': 'Failed to parse AI response',
        'raw_response': responseText,
      };
    }
  }

  Future<String?> generateBusinessInsights(String salesDataSummary) async {
    try {
      final prompt = 'Analyze the following sales summary and provide 3 key actionable business insights for the owner to improve sales: \n$salesDataSummary';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ API Quota Exceeded: You have hit the daily free limit for your API key. To continue using AI features today, please generate a new API key in Google AI Studio or add a billing account.";
      }
      return "⚠️ AI Service Error: Unable to generate insights at this moment.";
    }
  }
}
