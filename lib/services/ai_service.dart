import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // TODO: Replace with a valid API key or fetch from a secure configuration
  static const String _apiKey = 'AIzaSyAU2GzT0EGXT-MT89emrGuZ8ScaU7RFtSg';
  
  late final GenerativeModel _model;
  
  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String?> generateProductDescription(String productName, String keywords) async {
    final prompt = 'Write a compelling product description for "$productName". Keywords: $keywords. Keep it concise, engaging, and suitable for an e-commerce app.';
    
    // Allow exceptions to bubble up to be handled by UI
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text;
  }

  Future<String?> generateMarketingCaption(String productName, String description, String platform) async {
    final prompt = 'Create a catchy social media caption for "$productName" on $platform. Description: $description. Include hashtags.';
    
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text;
  }

  Future<String?> generateBusinessInsights(String salesDataSummary) async {
    final prompt = 'Analyze the following sales summary and provide 3 key actionable business insights for the owner to improve sales: \n$salesDataSummary';
    
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text;
  }
}
