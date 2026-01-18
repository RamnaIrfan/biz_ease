import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyCzbC_GFDRmPqG36-_4MkKaRUsrplqygik';
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  try {
    print('Checking available models...');
    // We can't directly list models via the SDK's GenerativeModel class easily in all versions, 
    // but we can try a simple generation to test specific model names.
    
    final modelsToTest = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-1.0-pro',
      'gemini-pro',
      'gemini-1.5-flash-001',
      'gemini-1.5-flash-latest'
    ];

    for (final m in modelsToTest) {
      print('Testing model: $m');
      try {
        final testModel = GenerativeModel(model: m, apiKey: apiKey);
        final response = await testModel.generateContent([Content.text('Hello')]);
        print('SUCCESS: $m worked! Response: ${response.text}');
        return; // Found one that works
      } catch (e) {
        print('FAILED: $m. Error: ${e.toString().replaceAll('\n', ' ')}');
      }
    }
    
    print('All tested models failed.');

  } catch (e) {
    print('Fatal error: $e');
  }
}
