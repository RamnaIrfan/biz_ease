# 📈 3. Business Insights Agent Documentation

## 📂 File Location
*   **Logic:** `lib/services/ai_service.dart`
*   **UI Integration:** `lib/widgets/business_insights_card.dart`

## 🎯 What it does
The **Business Insights Agent** is an analytical AI that acts as a financial consultant for the Business Owner. It lives directly on the Owner's Dashboard. 
Instead of forcing the owner to manually calculate trends, read complex charts, or figure out what is selling well, the Agent reads the raw database statistics (Total Sales, Revenue, Order Counts, Current Stock levels) and generates plain-English, actionable business advice.

## ⚙️ How it works (Functionality)
1. **Data Aggregation:** The UI (`business_insights_card.dart`) pulls live statistics from the `OwnerService`. It calculates total revenue, counts pending vs. completed orders, and identifies which products have the highest and lowest stock.
2. **Context Compilation:** It formats all this raw data into a readable paragraph (the "Sales Summary").
3. **AI Prompting:** This summary is injected into a strict prompt telling the AI to *"analyze the following sales summary and provide 3 key actionable business insights"*.
4. **State Management:** The UI handles loading states, error boundaries (like waiting 60 seconds if the free API quota is exceeded), and displays the final insights beautifully on the dashboard.

## 💻 Full Code Explanation

### 1. The AI Logic (`lib/services/ai_service.dart`)
```dart
  Future<String?> generateBusinessInsights(String salesDataSummary) async {
    try {
      // 1. INSTRUCTION PROMPT
      // We explicitly ask for exactly 3 actionable insights to keep the UI clean.
      final prompt = 'Analyze the following sales summary and provide 3 key actionable business insights for the owner to improve sales: \\n\$salesDataSummary';
      
      final content = [Content.text(prompt)];
      
      // 2. GENERATION
      final response = await _model.generateContent(content);
      return response.text;
      
    } catch (e) {
      // 3. ERROR & QUOTA HANDLING
      // Catch Google Cloud API limits and return user-friendly UI warnings.
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
        return "⚠️ API Quota Exceeded: You have hit the daily free limit for your API key. To continue using AI features today, please generate a new API key in Google AI Studio or add a billing account.";
      }
      return "⚠️ AI Service Error: Unable to generate insights at this moment.";
    }
  }
```

### 2. The Data Aggregation & UI Execution (`lib/widgets/business_insights_card.dart`)
```dart
class BusinessInsightsCard extends StatefulWidget { ... }

class _BusinessInsightsCardState extends State<BusinessInsightsCard> {
  final AIService _aiService = AIService();
  final OwnerService _ownerService = OwnerService();
  String? _insights;

  Future<void> _generateInsights() async {
    // ... UI loading state set to true ...

    try {
      // STEP 1: FETCH RAW DATA FROM FIREBASE
      final stats = await _ownerService.getOwnerStats(widget.ownerId);
      final products = await _ownerService.getOwnerProducts(widget.ownerId).first;

      // STEP 2: CALCULATE METRICS
      int totalOrders = stats['totalOrders'] ?? 0;
      double totalRevenue = stats['totalRevenue'] ?? 0.0;
      int pendingOrders = stats['pendingOrders'] ?? 0;
      int completedOrders = stats['completedOrders'] ?? 0;

      // Identify low stock products
      final lowStockProducts = products.where((p) => p.stock < 5).toList();
      String lowStockInfo = lowStockProducts.isEmpty 
          ? "No products are low in stock." 
          : "Low stock products: \${lowStockProducts.map((p) => p.name).join(', ')}.";

      // STEP 3: COMPILE THE CONTEXT
      // We turn raw numbers into a sentence the AI can easily understand.
      String summary = '''
        Total Orders: \$totalOrders
        Total Revenue: Rs. \$totalRevenue
        Pending Orders: \$pendingOrders
        Completed Orders: \$completedOrders
        \$lowStockInfo
      ''';

      // STEP 4: TRIGGER THE AI
      final result = await _aiService.generateBusinessInsights(summary);

      // STEP 5: UPDATE THE UI
      setState(() {
        _insights = result;
      });
      
    } catch (e) {
      // Fallback error UI
      setState(() {
        _insights = "⚠️ Could not analyze data at this time.";
      });
    }
  }
  
  // The Build method contains an "Generate Insights" button that turns into
  // a "Try Again" button if an error/quota limit occurs.
}
```
