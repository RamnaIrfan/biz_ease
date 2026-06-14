# BizEase Agentic Modules Summary

This document outlines the agentic modules integrated into the BizEase application. These modules leverage AI to provide autonomous, intelligent business logic.

## 1. AI Service (`lib/services/ai_service.dart`)
This is the foundational AI service using the Gemini model (`gemini-flash-latest`) to generate text and data-driven insights. It is responsible for:
- **Product Descriptions & Captions:** Generating compelling product descriptions and social media captions based on keywords.
- **Campaign Generation:** Autonomously creating full, multi-platform JSON marketing campaigns (Instagram, Facebook, TikTok) complete with design prompts, hooks, and captions. It uses Vision AI if a product image is provided.
- **Business Insights:** Analyzing raw sales data summaries to produce actionable business insights for the owner.

## 2. Marketing Agent Service (`lib/services/marketing_agent_service.dart`)
This agent orchestrates the marketing workflow autonomously. 
- **Analysis & Generation:** It fetches product images and uses the `AIService` to generate tailored marketing content across platforms.
- **Execution:** It formats the AI-generated campaign into a structured social media post, appending product links and hashtags, and then triggers the system's share sheet to deploy the campaign.
- **Logging:** Automatically logs the sharing event to a webhook for analytics.

## 3. Support Agent Service (`lib/services/support_agent_service.dart`)
A robust, tool-equipped conversational AI agent that assists customers. It has true agentic behavior by deciding when to call system functions (tools) during a conversation:
- **`check_order_status`:** Reads order details from Firestore based on the customer's query.
- **`cancel_order`:** Autonomously validates if an order is "pending" and cancels it if requested.
- **`search_products`:** Queries the product catalog to recommend items based on user text.
- **`send_whatsapp_message`:** Can trigger formal WhatsApp messages to customers for updates or notifications.
- It maintains conversation history and manages "thought signatures" to seamlessly execute multi-step requests.
