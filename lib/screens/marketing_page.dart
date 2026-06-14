import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/marketing_agent_service.dart';
import '../screens/auth_provider.dart';
import '../widgets/common_image.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _instructionController = TextEditingController(
    text: "Create a catchy launch campaign for my social media."
  );
  
  ProductModel? _selectedProduct;
  bool _isGenerating = false;
  bool _isPosting = false;
  Map<String, dynamic>? _generatedCampaign;
  
  final List<String> _platforms = ['Instagram', 'Facebook', 'TikTok'];
  final List<String> _selectedPlatforms = ['Instagram', 'Facebook', 'TikTok'];

  static const orange = Color(0xFFD88A1F);

  @override
  Widget build(BuildContext context) {
    final ownerId = Provider.of<AuthProvider>(context).userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Marketing Agency Hub'),
        backgroundColor: orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Professional Marketing, Zero Effort.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Let the AI Agent design your next viral campaign.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 1. Select Product
              const Text('1. Choose Product to Promote', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<ProductModel>>(
                stream: ProductService().getProductsByOwner(ownerId ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final products = snapshot.data!;
                  
                  // Safety: Ensure _selectedProduct is actually in the current list
                  if (_selectedProduct != null && !products.contains(_selectedProduct)) {
                    _selectedProduct = null;
                  }

                  return DropdownButtonFormField<ProductModel>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'Select a product',
                    ),
                    value: _selectedProduct,
                    items: products.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _selectedProduct = v;
                      _generatedCampaign = null; // Reset campaign on product change
                    }),
                    validator: (v) => v == null ? 'Please select a product' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Instructions
              const Text('2. Your Creative Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Make it look luxury, mention a 20% discount for Sunday.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Platforms
              const Text('3. Target Platforms', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _platforms.map((p) {
                  final isSelected = _selectedPlatforms.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: isSelected,
                    selectedColor: orange.withAlpha(50),
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedPlatforms.add(p);
                        else _selectedPlatforms.remove(p);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Generate Button
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCampaign,
                icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Agency is Thinking...' : 'Generate Full Campaign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // --- CAMPAIGN PREVIEW ---
              if (_generatedCampaign != null) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const Text('🚀 Campaign Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                
                _buildCampaignCard('Instagram', _generatedCampaign!['instagram']),
                _buildCampaignCard('Facebook', _generatedCampaign!['facebook']),
                _buildCampaignCard('TikTok', _generatedCampaign!['tiktok']),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isPosting ? null : _postCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('APPROVE & POST TO ALL PLATFORMS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(String title, dynamic data) {
    if (data == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ THE POSTER (Visual Preview)
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300), // Keep it compact and sharp
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: title == 'TikTok' ? 9 / 16 : 
                               title == 'Facebook' ? 1.91 / 1 : 1 / 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CommonImage(
                        imageUrl: _selectedProduct!.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 🌑 Gradient Overlay (Better Text Contrast)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(50),
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 🏷️ Price Tag (Minimalist)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rs. ${_selectedProduct!.price}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // 🏷️ Title Overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      _selectedProduct!.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['design_prompt'] != null) ...[
                  const Text('🎨 AI Design Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: orange)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['design_prompt'], 
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const Text('📝 Post Caption:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: orange)),
                const SizedBox(height: 4),
                SelectableText(
                  data['caption'] ?? data['post_content'] ?? data['video_script'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                
                if (data['hashtags'] != null) ...[
                  const SizedBox(height: 8),
                  Text(data['hashtags'], style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
                
                if (data['hook'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Hook: ${data['hook']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // 📤 Individual Share & Export Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final agent = MarketingAgentService();
                          agent.postCampaign(
                            product: _selectedProduct!,
                            campaignData: _generatedCampaign!,
                            platforms: [title],
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: Text('Post to $title'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange.withAlpha(200),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final agent = MarketingAgentService();
                            await agent.downloadCampaign(
                              product: _selectedProduct!,
                              campaignData: _generatedCampaign!,
                              platform: title,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Download Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final agent = MarketingAgentService();
      final campaign = await agent.generateAndReviewCampaign(
        product: _selectedProduct!,
        instructions: _instructionController.text,
        platforms: _selectedPlatforms,
      );
      
      setState(() {
        _isGenerating = false;
        _generatedCampaign = campaign;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _postCampaign() async {
    setState(() => _isPosting = true);
    try {
      final agent = MarketingAgentService();
      await agent.postCampaign(
        product: _selectedProduct!,
        campaignData: _generatedCampaign!,
        platforms: _selectedPlatforms,
      );
      
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign Posted Successfully! 🚀'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
