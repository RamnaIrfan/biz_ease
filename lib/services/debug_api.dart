import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyBb9mQmY2EnvSg5nr18YmJ3apVX6PGqiKA';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  print('Querying Google Gemini API for available models...');
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Response Status: ${response.statusCode}');
    
    try {
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      
      if (jsonResponse.containsKey('error')) {
        print('API ERROR: ${jsonResponse['error']['message']}');
      } else if (jsonResponse.containsKey('models')) {
        final models = jsonResponse['models'] as List;
        print('FOUND ${models.length} MODELS.');
        
        print('Searching for a valid text generation model...');
        String? bestModel;
        
        for (var m in models) {
          final name = m['name'].toString();
          final methods = (m['supportedGenerationMethods'] as List? ?? []).map((e) => e.toString()).toList();
          
          if (methods.contains('generateContent')) {
             print(' - CANDIDATE: $name');
             // Prefer standard names if possible
             if (name.endsWith('gemini-1.5-flash')) bestModel = name;
             if (bestModel == null && name.contains('flash')) bestModel = name; // Fallback
             if (bestModel == null) bestModel = name; // Fallback to first one
          }
        }
        
        if (bestModel != null) {
          print('RECOMMENDED MODEL: $bestModel');
        } else {
          print('NO GENERATION MODELS FOUND.');
        }

      } else {
        print('Unknown response format: $responseBody');
      }
    } catch (e) {
      print('Failed to parse JSON: $e');
      print('Raw Body: $responseBody');
    }
    
  } catch (e) {
    print('Error making request: $e');
  } finally {
    client.close();
  }
}
