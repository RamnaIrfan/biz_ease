# 🤖 1. Support Agent Module Documentation

## 📂 File Location
`lib/services/support_agent_service.dart`

## 🎯 What it does
The **Support Agent** acts as an autonomous virtual assistant for customers using the BizEase app. Instead of a standard chatbot that only answers FAQs, this is an **Agentic AI**—meaning it has the ability to actively perform actions in the app on behalf of the user. 

If a customer asks "Where is my order?", the Agent doesn't just guess; it physically triggers the `check_order_status` function, retrieves the real-time order data from the database, and responds naturally.

## ⚙️ How it works (Functionality)
The Support Agent utilizes **Google Gemini's Function Calling (Tools) API**. 
1. **Tool Definition:** The agent is initialized with a list of "Tools" (functions) it is allowed to use. These include `check_order_status`, `cancel_order`, `search_products`, and `send_whatsapp_message`.
2. **Conversation Loop:** When a user sends a message, the AI analyzes the intent. If the AI realizes it needs data, it pauses the conversation and tells the app, *"I need you to run the `check_order_status` function with Order ID 123"*.
3. **Execution & Feedback:** The app executes the Dart function, retrieves the Firestore data, and sends the raw JSON data back to the AI.
4. **Final Response:** The AI reads the data and formulates a polite, natural-sounding response to the user.

## 💻 Full Code Explanation

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'communication_service.dart';
import '../api_key.dart';
import '../models/order_model.dart';

class SupportAgentService {
  late final GenerativeModel _model;
  
  // Dependency injection: the agent needs access to the database services to do its job.
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  
  // Stores the ongoing conversation history so the AI remembers context.
  final List<Content> _chatHistory = [];

  SupportAgentService() {
    // 1. DEFINE TOOLS
    // Here we define the "Function Declarations". We tell the AI the name of the function, 
    // what it does, and what parameters (like orderId) it requires.
    final tools = [
      Tool(functionDeclarations: [
        FunctionDeclaration(
          'check_order_status',
          'Get the current status and details of a customer order.',
          Schema.object(properties: {
            'orderId': Schema.string(description: 'The unique ID of the order.'),
          }, requiredProperties: ['orderId']),
        ),
        FunctionDeclaration(
          'cancel_order',
          'Attempt to cancel an order. Only possible if the order status is "pending".',
          Schema.object(properties: {
            'orderId': Schema.string(description: 'The unique ID of the order to cancel.'),
          }, requiredProperties: ['orderId']),
        ),
        FunctionDeclaration(
          'search_products',
          'Search for products in the catalog based on a text query (name or category).',
          Schema.object(properties: {
            'query': Schema.string(description: 'The search term (e.g., "red watch", "electronics").'),
          }, requiredProperties: ['query']),
        ),
        FunctionDeclaration(
          'send_whatsapp_message',
          'Send a formal WhatsApp message to the customer.',
          Schema.object(properties: {
            'phoneNumber': Schema.string(description: 'The customer phone number.'),
            'message': Schema.string(description: 'The content of the WhatsApp message.'),
          }, requiredProperties: ['phoneNumber', 'message']),
        ),
      ])
    ];

    // 2. INITIALIZE THE MODEL
    // We attach the API key, the tools, and a "System Instruction" which acts as the AI's personality.
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: APIKey.key,
      tools: tools,
      systemInstruction: Content.system('''
        You are the BizEase Support Agent. Your goal is to help customers...
      '''),
    );
  }

  // 3. MAIN COMMUNICATION LOOP
  Future<String> sendMessage(String message) async {
    final userContent = Content.text(message);
    
    try {
      // Append the new message to the chat history
      final List<Content> requestHistory = [..._chatHistory, userContent];
      
      // Ask Gemini for a response
      var response = await _model.generateContent(requestHistory);
      
      // 4. FUNCTION CALLING INTERCEPTOR
      // If the AI decides it needs to use a tool, it returns a "FunctionCall" instead of text.
      // The while-loop handles the tool execution.
      while (response.candidates.first.content.parts.any((p) => p is FunctionCall)) {
        final content = response.candidates.first.content;
        String toolResultsString = "SYSTEM: You executed the following tools:\n";
        
        for (final part in content.parts) {
          if (part is FunctionCall) {
            Object result;
            
            // Execute the corresponding actual Dart function based on what the AI asked for
            if (part.name == 'check_order_status') {
              final order = await _orderService.getOrder(part.args['orderId'] as String);
              result = order != null ? order.toMap() : {'error': 'Order not found'};
            } else if (part.name == 'cancel_order') {
               // ... logic to cancel the order in Firestore ...
            } else if (part.name == 'search_products') {
               // ... logic to search Firestore for products ...
            } else if (part.name == 'send_whatsapp_message') {
               // ... logic to trigger the WhatsApp API ...
            } else {
              result = {'error': 'Unknown tool'};
            }
            
            // Format the result into a string that the AI can read
            toolResultsString += "- Tool '${part.name}' returned:\n${jsonEncode(_cleanData(result))}\n\n";
          }
        }
        
        // 5. FEED THE DATA BACK TO THE AI
        // We inject the database results back into the conversation history as a text prompt.
        requestHistory.add(Content.model([TextPart("I am requesting external data using my tools...")]));
        requestHistory.add(Content.text(toolResultsString));
        
        // The AI reads the database results and generates the final text response.
        response = await _model.generateContent(requestHistory);
      }
      
      // 6. SAVE AND RETURN
      final responseText = response.text ?? "I'm sorry, I encountered an issue processing that.";
      _chatHistory.add(userContent);
      _chatHistory.add(response.candidates.first.content);
      
      return responseText;
      
    } catch (e) {
      // 7. ERROR HANDLING
      // Checks if the API Key has run out of its Daily Free Quota (429 Error).
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ Quota Exceeded: My API key has hit its daily limit!";
      }
      return "I'm having trouble connecting to my systems. Please try again in a moment.";
    }
  }

  // Helper function to convert complex Firestore Timestamps into readable strings for the AI.
  dynamic _cleanData(dynamic data) { ... }
}
```
