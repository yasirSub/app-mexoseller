import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';
import '../services/category_service.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product; // For edit mode

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _loading = false;
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isCategoryDropdownOpen = false;
  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;
  int?
  _expandedCategoryId; // Track which category is expanded to show subcategories
  bool get isEditMode => widget.product != null;

  // Image handling
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock']?.toString() ?? '';
      _selectedCategoryId = widget.product!['category_id'];
      _selectedCategoryName = widget.product!['category']?['name'];
      // Load existing image if available
      final productImages =
          widget.product!['image'] ?? widget.product!['images'];
      if (productImages != null) {
        if (productImages is String) {
          _uploadedImageUrl = productImages;
        } else if (productImages is List && productImages.isNotEmpty) {
          _uploadedImageUrl = productImages[0];
        }
      }
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (_categories.isNotEmpty) return; // Already loaded

    setState(() => _isLoadingCategories = true);
    try {
      final result = await CategoryService.getCategories(parentId: 'null');
      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>? ?? [];
        setState(() {
          _categories = data;
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  void _toggleCategoryDropdown() {
    if (_isCategoryDropdownOpen) {
      setState(() {
        _isCategoryDropdownOpen = false;
      });
    } else {
      if (_categories.isEmpty) {
        _loadCategories().then((_) {
          if (mounted) {
            _showCategoryBottomSheet();
          }
        });
      } else {
        _showCategoryBottomSheet();
      }
    }
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Store expanded category ID in a variable that persists
        int? localExpandedId = _expandedCategoryId;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Categories List
                  Flexible(
                    child: _isLoadingCategories
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No categories available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _categories.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final category =
                                  _categories[index] as Map<String, dynamic>;
                              final isSelected =
                                  _selectedCategoryId == category['id'];
                              final hasSubcategories =
                                  (category['subcategories'] as List<dynamic>?)
                                      ?.isNotEmpty ??
                                  false;
                              final isExpanded =
                                  localExpandedId == category['id'];
                              final subcategories =
                                  category['subcategories'] as List<dynamic>? ??
                                  [];

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (hasSubcategories) {
                                        // Toggle expansion for subcategories
                                        setModalState(() {
                                          if (localExpandedId ==
                                              category['id']) {
                                            localExpandedId = null;
                                            _expandedCategoryId = null;
                                          } else {
                                            localExpandedId = category['id'];
                                            _expandedCategoryId =
                                                category['id'];
                                          }
                                        });
                                      } else {
                                        // No subcategories, select directly
                                        _selectCategoryFromList(category);
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      color: isSelected
                                          ? Colors.deepPurple.withOpacity(0.1)
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Icon(
                                            hasSubcategories
                                                ? (isExpanded
                                                      ? Icons.folder_open
                                                      : Icons.folder)
                                                : Icons.category_outlined,
                                            color: isSelected
                                                ? Colors.deepPurple
                                                : Colors.grey.shade600,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category['name'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.deepPurple
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                if (hasSubcategories &&
                                                    !isExpanded)
                                                  Text(
                                                    '${subcategories.length} subcategories',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (hasSubcategories)
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey.shade600,
                                            ),
                                          if (isSelected && !hasSubcategories)
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.deepPurple,
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Show subcategories if expanded
                                  if (isExpanded && hasSubcategories)
                                    Container(
                                      color: Colors.grey.shade50,
                                      child: Column(
                                        children: subcategories.map<Widget>((
                                          subcategory,
                                        ) {
                                          final subIsSelected =
                                              _selectedCategoryId ==
                                              subcategory['id'];
                                          return InkWell(
                                            onTap: () {
                                              _selectCategoryFromList(
                                                subcategory
                                                    as Map<String, dynamic>,
                                                parentCategoryName:
                                                    category['name'],
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                left: 40,
                                              ),
                                              color: subIsSelected
                                                  ? Colors.deepPurple
                                                        .withOpacity(0.1)
                                                  : Colors.transparent,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .subdirectory_arrow_right,
                                                    color: subIsSelected
                                                        ? Colors.deepPurple
                                                        : Colors.grey.shade600,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      subcategory['name'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            subIsSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        color: subIsSelected
                                                            ? Colors.deepPurple
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  if (subIsSelected)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.deepPurple,
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Product Image',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to add image',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  void _selectCategoryFromList(
    Map<String, dynamic> category, {
    String? parentCategoryName,
  }) {
    setState(() {
      _selectedCategoryId = category['id'];
      if (parentCategoryName != null && parentCategoryName.isNotEmpty) {
        _selectedCategoryName = '$parentCategoryName > ${category['name']}';
      } else {
        _selectedCategoryName = category['name'];
      }
      _expandedCategoryId = null; // Close any expanded categories
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _uploadedImageUrl = null; // Clear previous URL
        });
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final response = await ApiService.uploadImage(
        Endpoints.uploadImage,
        _selectedImageFile!,
        type: 'product',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String imageUrl = data['url'] ?? '';
        debugPrint('🖼️ Original image URL from backend: $imageUrl');

        // Fix malformed URLs that have double base URLs (e.g., http://192.168.31.129:8080http://localhost:8000/...)
        if (imageUrl.contains('http://') &&
            imageUrl.split('http://').length > 2) {
          // Extract just the path part after the last http://
          final parts = imageUrl.split('http://');
          if (parts.length >= 2) {
            final lastPart = parts.last;
            final uri = Uri.tryParse('http://$lastPart');
            if (uri != null) {
              final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
              imageUrl =
                  '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
              debugPrint('🖼️ Fixed malformed double URL: $imageUrl');
            }
          }
        }
        // If URL is already a full URL with localhost, replace it
        else if (imageUrl.contains('localhost')) {
          try {
            final uri = Uri.tryParse(imageUrl);
            if (uri != null) {
              final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
              // Only use the path part, not the full URL
              imageUrl =
                  '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
              debugPrint('🖼️ Fixed localhost URL in upload: $imageUrl');
            }
          } catch (e) {
            debugPrint('❌ Error parsing localhost URL: $e');
          }
        }
        // Convert relative URL to full URL if needed (only if not already a full URL)
        else if (imageUrl.startsWith('/storage/')) {
          // Extract base URL from ApiService
          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
          imageUrl = '$baseUrl$imageUrl';
          debugPrint('🖼️ Converted relative URL to full: $imageUrl');
        }
        // If URL already contains the correct base URL, don't modify it
        else if (imageUrl.startsWith('http://') &&
            imageUrl.contains('192.168.31.129:8080')) {
          // URL is already correct, no need to modify
          debugPrint('🖼️ URL already correct: $imageUrl');
        }

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
        debugPrint('✅ Image uploaded successfully: $_uploadedImageUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('❌ Image upload failed: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // If image was uploaded but not yet saved, upload it now
      if (_selectedImageFile != null && _uploadedImageUrl == null) {
        await _uploadImage();
        if (_uploadedImageUrl == null) {
          setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait for image upload to complete'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_uploadedImageUrl != null) 'images': [_uploadedImageUrl],
      };

      debugPrint('📦 Adding product with data: $data');
      debugPrint('📦 Selected Category ID: $_selectedCategoryId');

      final response = isEditMode
          ? await ApiService.put(
              '${Endpoints.products}/${widget.product!['id']}',
              data,
            )
          : await ApiService.post(Endpoints.products, data);

      debugPrint('📦 Product API Status: ${response.statusCode}');
      debugPrint('📦 Product API Response: ${response.body}');

      setState(() => _loading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Product updated successfully'
                    : 'Product added successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
          return;
        } else {
          debugPrint('❌ Product API returned success: false');
          debugPrint('❌ Error message: ${body['message']}');
        }
      } else {
        debugPrint('❌ Product API Error: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        debugPrint('❌ Error response: $errorBody');
      }

      if (!mounted) return;
      final errorMessage =
          response.statusCode == 200 || response.statusCode == 201
          ? (json.decode(response.body)['message'] ?? 'Failed to save product')
          : 'Failed to save product (Status: ${response.statusCode})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        // Custom curved app bar matching dashboard style
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isEditMode ? 'Edit Product' : 'Add New Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              GestureDetector(
                onTap: (_selectedImageFile == null && _uploadedImageUrl == null)
                    ? _showImageSourceDialog
                    : null,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Display image if available
                      if (_selectedImageFile != null ||
                          _uploadedImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _selectedImageFile != null
                              ? Image.file(
                                  _selectedImageFile!,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                )
                              : _uploadedImageUrl != null
                              ? Image.network(
                                  _uploadedImageUrl!,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
                                )
                              : _buildImagePlaceholder(),
                        )
                      else
                        _buildImagePlaceholder(),
                      // Upload loading overlay
                      if (_isUploadingImage)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Change image button (when image exists)
                      if ((_selectedImageFile != null ||
                              _uploadedImageUrl != null) &&
                          !_isUploadingImage)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _showImageSourceDialog,
                              tooltip: 'Change Image',
                            ),
                          ),
                        ),
                      // Remove image button
                      if ((_selectedImageFile != null ||
                              _uploadedImageUrl != null) &&
                          !_isUploadingImage)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImageFile = null;
                                  _uploadedImageUrl = null;
                                });
                              },
                              tooltip: 'Remove Image',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'Enter product name',
                  prefixIcon: Icon(
                    Icons.shopping_bag_outlined,
                    color: colorScheme.primary,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  alignLabelWithHint: false,
                  isDense: false,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
                textAlignVertical: TextAlignVertical.center,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Product name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  alignLabelWithHint: true,
                  isDense: false,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
                maxLines: 4,
                textAlignVertical: TextAlignVertical.top,
              ),
              const SizedBox(height: 16),

              // Category Selection
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleCategoryDropdown,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedCategoryName ??
                                    'Select Product Category',
                                style: TextStyle(
                                  color: _selectedCategoryName != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 16,
                                  fontWeight: _selectedCategoryName != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  height: 1.2,
                                ),
                              ),
                              if (_selectedCategoryName == null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Choose a category for your product',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price *',
                        hintText: '0.00',
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          color: colorScheme.primary,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          16,
                          20,
                          16,
                          20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        alignLabelWithHint: false,
                        isDense: false,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid price';
                        if (double.parse(v) < 0) return 'Must be positive';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock *',
                        hintText: '0',
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.primary,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          16,
                          20,
                          16,
                          20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        alignLabelWithHint: false,
                        isDense: false,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        if (int.parse(v) < 0) return 'Must be positive';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Update Product' : 'Add Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
