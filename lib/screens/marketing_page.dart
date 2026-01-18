import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedPlatform = 'Instagram';
  String? _generatedCaption;
  bool _isGenerating = false;

  final List<String> _platforms = ['Instagram', 'Facebook', 'Twitter', 'LinkedIn'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Marketing Assistant'),
        backgroundColor: const Color(0xFFD88A1F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Generate catchy social media captions for your products!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Product Description/Key Features',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedPlatform,
                items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _selectedPlatform = v!),
                decoration: InputDecoration(
                  labelText: 'Platform',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCaption,
                icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Caption'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD88A1F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
              if (_generatedCaption != null) ...[
                const SizedBox(height: 32),
                const Text('Generated Caption:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _generatedCaption!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedCaption!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Caption copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateCaption() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isGenerating = true);
    
    final aiService = AIService();
    
    try {
      final caption = await aiService.generateMarketingCaption(
        _productNameController.text,
        _descriptionController.text,
        _selectedPlatform,
      );
      
      setState(() {
        _isGenerating = false;
        _generatedCaption = caption;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        // Strip "GenerativeAIException: " if present for cleaner message
        final errorMessage = e.toString().replaceAll('GenerativeAIException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
