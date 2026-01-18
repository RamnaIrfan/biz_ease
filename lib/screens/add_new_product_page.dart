import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../screens/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/common_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class AddNewProductPage extends StatefulWidget {
  final ProductModel? product;
  const AddNewProductPage({super.key, this.product});

  @override
  State<AddNewProductPage> createState() => _AddNewProductPageState();
}

class _AddNewProductPageState extends State<AddNewProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imagePath;
  bool _isUploading = false;
  bool _isGeneratingDescription = false;

  bool _isSaving = false;
  late String _productId;

  String _selectedCategory = 'Electronics';
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Accessories',
    'Home & Garden',
    'Books',
    'Beauty',
    'Fashion',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _descriptionController.text = widget.product!.description;
      _selectedCategory = widget.product!.category;
      _imagePath = widget.product!.imageUrl;
      _productId = widget.product!.id;
    } else {
      _productId = const Uuid().v4();
    }
  }

  static const orange = Color(0xFFD88A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add New Product'),
        backgroundColor: orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Upload
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isUploading 
                          ? const Center(child: CircularProgressIndicator())
                          : CommonImage(
                              imageUrl: _imagePath,
                              placeholderIcon: Icons.add_a_photo,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        debugPrint('DEBUG: Image upload button pressed');
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );

                        if (result != null) {
                          debugPrint('DEBUG: File selected: ${result.files.single.name}');
                          setState(() => _isUploading = true);
                          
                          try {
                            String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
                            String downloadUrl;

                            if (kIsWeb) {
                              debugPrint('DEBUG: Running on Web, uploading bytes');
                              if (result.files.single.bytes == null) throw 'Could not read file data';
                              
                              downloadUrl = await StorageService().uploadProductImage(
                                bytes: result.files.single.bytes,
                                fileName: fileName,
                              );
                            } else {
                              debugPrint('DEBUG: Running on Mobile/Desktop, uploading file');
                              final pickedPath = result.files.single.path;
                              if (pickedPath == null) throw 'Could not find file path';
                              
                              downloadUrl = await StorageService().uploadProductImage(
                                path: pickedPath,
                                fileName: fileName,
                              );
                            }

                            debugPrint('DEBUG: Upload successful! URL: $downloadUrl');
                            setState(() {
                              _imagePath = downloadUrl;
                              _isUploading = false;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image uploaded to cloud successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isUploading = false);
                            debugPrint('ERROR: Image upload failed: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to upload image: $e')),
                              );
                            }
                          }
                        } else {
                          debugPrint('DEBUG: No file selected (user cancelled)');
                        }
                      },
                      child: Text(_imagePath == null ? 'Upload Product Image' : 'Change Image'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Product Name
              const Text(
                'Product Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter product name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price
              const Text(
                'Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter price',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Stock Quantity
              const Text(
                'Stock Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description
              // Description Header with AI Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _isGeneratingDescription
                        ? null
                        : () async {
                            if (_nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a product name first'),
                                ),
                              );
                              return;
                            }
                            setState(() => _isGeneratingDescription = true);
                            
                            final aiService = AIService();
                            // Combining name and category as keywords
                            final keywords = "${_nameController.text}, $_selectedCategory";
                            
                            try {
                              final description = await aiService.generateProductDescription(
                                _nameController.text,
                                keywords,
                              );

                              setState(() => _isGeneratingDescription = false);

                              if (description != null) {
                                setState(() {
                                  _descriptionController.text = description;
                                });
                              }
                            } catch (e) {
                              setState(() => _isGeneratingDescription = false);
                              if (context.mounted) {
                                final errorMessage = e.toString().replaceAll('GenerativeAIException: ', '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('AI Error: $errorMessage'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    icon: _isGeneratingDescription
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(_isGeneratingDescription ? 'Generating...' : 'Generate with AI'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter product description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () {
                    if (_formKey.currentState!.validate()) {
                      // Save product logic
                      _saveProduct(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                     disabledBackgroundColor: orange.withAlpha((0.6 * 255).toInt()),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.product != null ? 'Update Product' : 'Add Product',
                        style: const TextStyle(fontSize: 16),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct(BuildContext context) async {
    // Prevent multiple simultaneous saves (race condition protection)
    if (_isSaving) {
      debugPrint('Save already in progress, ignoring duplicate call');
      return;
    }
    
    // Set flag immediately to prevent race conditions from rapid button clicks
    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.userId;

    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Owner ID not found.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Warn if no image uploaded (optional but recommended)
    if (_imagePath == null || _imagePath!.isEmpty) {
      debugPrint('WARNING: No image uploaded for this product');
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Product Image'),
          content: const Text(
            'You haven\'t uploaded a product image. Products with images tend to sell better. Do you want to continue without an image?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue Without Image'),
            ),
          ],
        ),
      );

      if (proceed != true) {
        setState(() => _isSaving = false);
        return;
      }
    }

    // Debug logging to track image URL
    debugPrint('DEBUG: Saving product with image path: $_imagePath');

    final product = (widget.product ?? ProductModel(
      id: _productId,
      ownerId: ownerId,
      name: '',
      price: 0,
      stock: 0,
      category: '',
      description: '',
      createdAt: DateTime.now(),
    )).copyWith(
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      stock: int.tryParse(_stockController.text) ?? 0,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      imageUrl: _imagePath,
    );

    // Debug: Verify product has imageUrl
    debugPrint('DEBUG: Product imageUrl after copyWith: ${product.imageUrl}');

    try {
      final productService = ProductService();
      if (widget.product != null) {
        await productService.updateProduct(product);
      } else {
        await productService.createProduct(product);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null ? 'Product updated successfully!' : 'Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}