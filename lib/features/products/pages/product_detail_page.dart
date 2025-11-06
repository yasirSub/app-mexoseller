import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';
import 'add_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Map<String, dynamic> _product;
  bool _isLoading = false;
  int _imageRefreshKey = 0; // Key to force image refresh

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _refreshProduct() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '${Endpoints.products}/${_product['id']}',
      );
      debugPrint('🔄 Refreshing product ${_product['id']}');
      debugPrint('🔄 Response status: ${response.statusCode}');
      debugPrint('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final updatedProduct = data['data'];
          debugPrint(
            '🔄 Updated product image: ${updatedProduct['image'] ?? updatedProduct['images']}',
          );
          setState(() {
            _product = updatedProduct;
            _isLoading = false;
            _imageRefreshKey++; // Increment key to force image refresh
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing product: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = _product['name'] ?? 'Unnamed Product';
    final description = _product['description'] ?? 'No description available';
    final price = _product['price'] ?? 0.0;
    final stock = _product['stock'] ?? 0;
    final category = _product['category'];
    final categoryName = category != null ? category['name'] : 'No Category';
    final sku = _product['sku'] ?? 'N/A';
    final status = _product['status'] ?? 'active';
    final createdAt = _product['created_at'] ?? '';
    final updatedAt = _product['updated_at'] ?? '';

    // Get image URL
    String? imageUrl;
    final productImage = _product['image'] ?? _product['images'];
    debugPrint('🖼️ Product image data: $productImage');
    debugPrint('🖼️ Product image type: ${productImage.runtimeType}');

    if (productImage != null) {
      if (productImage is String) {
        imageUrl = productImage;
      } else if (productImage is List && productImage.isNotEmpty) {
        imageUrl = productImage[0];
      }
    }

    debugPrint('🖼️ Extracted imageUrl: $imageUrl');

    // Fix malformed URLs that have double base URLs (e.g., http://192.168.31.129:8080http://localhost:8000/...)
    if (imageUrl != null &&
        imageUrl.contains('http://') &&
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
    // Fix localhost URLs to use the correct server IP
    else if (imageUrl != null && imageUrl.contains('localhost')) {
      try {
        final uri = Uri.tryParse(imageUrl);
        if (uri != null) {
          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
          // Only use the path part, not the full URL
          imageUrl =
              '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
          debugPrint('🖼️ Fixed localhost URL: $imageUrl');
        }
      } catch (e) {
        debugPrint('❌ Error parsing localhost URL: $e');
      }
    }
    // Convert relative URL to full URL if needed (only if not already a full URL)
    else if (imageUrl != null && imageUrl.startsWith('/storage/')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      imageUrl = '$baseUrl$imageUrl';
      debugPrint('🖼️ Converted to full URL: $imageUrl');
    }
    // If URL already contains the correct base URL, don't modify it
    else if (imageUrl != null &&
        imageUrl.startsWith('http://') &&
        imageUrl.contains('192.168.31.129:8080')) {
      // URL is already correct, no need to modify
      debugPrint('🖼️ URL already correct: $imageUrl');
    }

    // Add cache-busting parameter to force refresh when image is updated
    if (imageUrl != null && imageUrl.isNotEmpty && _imageRefreshKey > 0) {
      final uri = Uri.parse(imageUrl);
      imageUrl = uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              't': _imageRefreshKey.toString(),
            },
          )
          .toString();
      debugPrint('🖼️ Image URL with cache-busting: $imageUrl');
    }

    final stockColor = stock > 10
        ? Colors.green
        : stock > 0
        ? Colors.orange
        : Colors.red;

    final statusColor = status.toString().toLowerCase() == 'active'
        ? Colors.green
        : status.toString().toLowerCase() == 'inactive'
        ? Colors.grey
        : Colors.red;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
                      children: const [
                        SizedBox(height: 4),
                        Text(
                          'Product Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProductPage(product: _product),
                        ),
                      );
                      if (result == true) {
                        // Refresh product details
                        await _refreshProduct();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshProduct,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Image
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                key: ValueKey(
                                  'product_image_${_product['id']}_$_imageRefreshKey',
                                ),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('❌ Image load error: $error');
                                  debugPrint(
                                    '❌ Image URL that failed: $imageUrl',
                                  );
                                  debugPrint('❌ Stack trace: $stackTrace');
                                  return _buildImagePlaceholder();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    debugPrint(
                                      '✅ Image loaded successfully: $imageUrl',
                                    );
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    const SizedBox(height: 24),

                    // Product Name
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price and Stock Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$price',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$stock units',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: stockColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Card
                    _buildDetailCard(
                      context,
                      theme,
                      icon: Icons.category_outlined,
                      title: 'Category',
                      value: categoryName,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),

                    // Description Card
                    if (description.isNotEmpty &&
                        description != 'No description available')
                      _buildDetailCard(
                        context,
                        theme,
                        icon: Icons.description_outlined,
                        title: 'Description',
                        value: description,
                        color: Colors.blue,
                        isMultiLine: true,
                      ),
                    if (description.isNotEmpty &&
                        description != 'No description available')
                      const SizedBox(height: 12),

                    // SKU Card
                    _buildDetailCard(
                      context,
                      theme,
                      icon: Icons.qr_code_outlined,
                      title: 'SKU',
                      value: sku,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.circle,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.toString().toUpperCase(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Created At
                    if (createdAt.isNotEmpty)
                      _buildDetailCard(
                        context,
                        theme,
                        icon: Icons.calendar_today_outlined,
                        title: 'Created',
                        value: _formatDate(createdAt),
                        color: Colors.grey,
                      ),
                    if (createdAt.isNotEmpty) const SizedBox(height: 12),

                    // Updated At
                    if (updatedAt.isNotEmpty)
                      _buildDetailCard(
                        context,
                        theme,
                        icon: Icons.update_outlined,
                        title: 'Last Updated',
                        value: _formatDate(updatedAt),
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isMultiLine = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: isMultiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: isMultiLine ? null : 1,
                  overflow: isMultiLine ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'No Image Available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
