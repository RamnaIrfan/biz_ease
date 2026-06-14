import 'dart:io';
import 'dart:convert';

import '../api_key.dart';

void main() async {
  final apiKey = APIKey.key;
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
        print('FOUND ${models.length} MODELS:');
        for (var m in models) {
          print(' - ${m['name']}');
        }
        
        print('\nSearching for a valid text generation model...');
        String? bestModel;
        
        print('Testing top candidates for content generation...');
        List<String> testModels = [
          'gemini-flash-latest',
          'gemini-flash-lite-latest',
          'gemini-3.1-flash-lite',
          'gemini-2.5-flash-lite',
          'gemini-3-flash-preview'
        ];

        for (var modelName in testModels) {
          print('\n--- TESTING MODEL: $modelName ---');
          final testUrl = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey');
          
          try {
            final testRequest = await client.postUrl(testUrl);
            testRequest.headers.contentType = ContentType.json;
            testRequest.write(jsonEncode({
              'contents': [{'parts': [{'text': 'Say hello'}]}]
            }));
            
            final testResponse = await testRequest.close();
            final testBody = await testResponse.transform(utf8.decoder).join();
            
            print('Status: ${testResponse.statusCode}');
            if (testResponse.statusCode == 200) {
              print('SUCCESS! Model $modelName is working.');
              print('Response: ${testBody.substring(0, (testBody.length > 100) ? 100 : testBody.length)}...');
            } else {
              print('FAILED: $testBody');
            }
          } catch (e) {
            print('Error testing $modelName: $e');
          }
        }

      } else {
        print('Unknown response format: $responseBody');
      }
    } catch (e) {
      print('Failed to parse JSON: $e');
    }
  } catch (e) {
    print('Error making request: $e');
  } finally {
    client.close();
  }
}
