import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/category_service.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final String? image;
  final int productsCount;
  final int outOfStockCount;
  final int subcategoriesCount;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.image,
    required this.productsCount,
    required this.outOfStockCount,
    required this.subcategoriesCount,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parent_id'],
      image: json['image'],
      productsCount: json['products_count'] ?? 0,
      outOfStockCount: json['out_of_stock_count'] ?? 0,
      subcategoriesCount: json['subcategories_count'] ?? 0,
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map((sub) => Category.fromJson(sub))
              .toList() ??
          [],
    );
  }
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

enum SortOption {
  nameAsc,
  nameDesc,
  productsAsc,
  productsDesc,
  subcategoriesAsc,
  subcategoriesDesc,
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _isLoading = true;
  String? _error;
  List<Category> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await CategoryService.getCategories(
        parentId: 'null', // Get main categories only
        search: search,
      );

      debugPrint('📦 Categories result: $result');

      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>? ?? [];
        debugPrint('📦 Parsed ${data.length} categories');

        setState(() {
          _categories = data.map((json) {
            try {
              final category = Category.fromJson(json as Map<String, dynamic>);
              debugPrint(
                '📦 Category: ${category.name} - Products: ${category.productsCount}',
              );
              return category;
            } catch (e) {
              debugPrint('❌ Error parsing category: $e');
              debugPrint('❌ Category JSON: $json');
              rethrow;
            }
          }).toList();
          _sortCategories();
          _isLoading = false;
        });
      } else {
        final errorMessage = result['message'] ?? 'Failed to load categories';
        debugPrint('❌ Categories API error: $errorMessage');
        setState(() {
          _error = errorMessage;
          _isLoading = false;
          _categories = [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception loading categories: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load categories: $e';
        _isLoading = false;
        _categories = [];
      });
    }
  }

  void _onSearchChanged(String value) {
    _loadCategories(search: value.isEmpty ? null : value);
  }

  void _sortCategories() {
    setState(() {
      switch (_currentSort) {
        case SortOption.nameAsc:
          _categories.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.nameDesc:
          _categories.sort((a, b) => b.name.compareTo(a.name));
          break;
        case SortOption.productsAsc:
          _categories.sort(
            (a, b) => a.productsCount.compareTo(b.productsCount),
          );
          break;
        case SortOption.productsDesc:
          _categories.sort(
            (a, b) => b.productsCount.compareTo(a.productsCount),
          );
          break;
        case SortOption.subcategoriesAsc:
          _categories.sort(
            (a, b) => a.subcategoriesCount.compareTo(b.subcategoriesCount),
          );
          break;
        case SortOption.subcategoriesDesc:
          _categories.sort(
            (a, b) => b.subcategoriesCount.compareTo(a.subcategoriesCount),
          );
          break;
      }
    });
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.nameAsc:
        return 'Name (A-Z)';
      case SortOption.nameDesc:
        return 'Name (Z-A)';
      case SortOption.productsAsc:
        return 'Products (Low-High)';
      case SortOption.productsDesc:
        return 'Products (High-Low)';
      case SortOption.subcategoriesAsc:
        return 'Subcategories (Low-High)';
      case SortOption.subcategoriesDesc:
        return 'Subcategories (High-Low)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Search Bar and Sort
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                // Compact Sort Button
                PopupMenuButton<SortOption>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sort,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Sort',
                  onSelected: (SortOption sort) {
                    setState(() {
                      _currentSort = sort;
                    });
                    _sortCategories();
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<SortOption>(
                      value: SortOption.nameAsc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.nameAsc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.nameAsc)),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortOption>(
                      value: SortOption.nameDesc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.nameDesc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.nameDesc)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<SortOption>(
                      value: SortOption.productsDesc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.productsDesc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.productsDesc)),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortOption>(
                      value: SortOption.productsAsc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.productsAsc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.productsAsc)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<SortOption>(
                      value: SortOption.subcategoriesDesc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.subcategoriesDesc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.subcategoriesDesc)),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortOption>(
                      value: SortOption.subcategoriesAsc,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == SortOption.subcategoriesAsc
                                ? Icons.check
                                : null,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(_getSortLabel(SortOption.subcategoriesAsc)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Categories List
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 80),
              const SizedBox(height: 24),
              Text(
                'Unable to load categories',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loadCategories,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No Product Categories Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Product categories will appear here.\nSelect a category when adding or editing your products.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category, theme);
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('beauty') ||
        name.contains('personal') ||
        name.contains('care')) {
      return Icons.face;
    } else if (name.contains('book') || name.contains('media')) {
      return Icons.menu_book;
    } else if (name.contains('clothes') ||
        name.contains('clothing') ||
        name.contains('fashion')) {
      return Icons.checkroom;
    } else if (name.contains('gadget') || name.contains('electronics')) {
      return Icons.devices;
    } else if (name.contains('home') || name.contains('living')) {
      return Icons.home;
    } else if (name.contains('mobile') || name.contains('phone')) {
      return Icons.smartphone;
    } else if (name.contains('food') || name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('sports') || name.contains('fitness')) {
      return Icons.sports_soccer;
    } else if (name.contains('toys') || name.contains('games')) {
      return Icons.toys;
    } else if (name.contains('health') || name.contains('medical')) {
      return Icons.medical_services;
    } else if (name.contains('automotive') || name.contains('car')) {
      return Icons.directions_car;
    } else if (name.contains('pet') || name.contains('animal')) {
      return Icons.pets;
    } else {
      return Icons.category;
    }
  }

  Widget _buildCategoryCard(Category category, ThemeData theme) {
    final isSelectionMode =
        ModalRoute.of(context)?.settings.arguments as bool? ?? false;

    return Builder(
      builder: (context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSelectionMode
              ? () => Navigator.pop(context, category)
              : category.subcategoriesCount > 0
              ? () => _showSubcategories(category)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: category.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            category.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getCategoryIcon(category.name),
                                color: theme.colorScheme.primary,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _getCategoryIcon(category.name),
                          color: theme.colorScheme.primary,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            '${category.productsCount} products',
                            Icons.inventory_2,
                            theme,
                            hasProducts: category.productsCount > 0,
                            isOutOfStock: category.outOfStockCount > 0,
                            outOfStockCount: category.outOfStockCount,
                          ),
                          if (category.subcategoriesCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatChip(
                              '${category.subcategoriesCount} subcategories',
                              Icons.subdirectory_arrow_right,
                              theme,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (category.subcategoriesCount > 0 && !isSelectionMode)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )
                else if (isSelectionMode)
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String text,
    IconData icon,
    ThemeData theme, {
    bool isOutOfStock = false,
    int outOfStockCount = 0,
    bool hasProducts = false,
  }) {
    // Only show green/red if there are products
    final shouldShowColor = hasProducts;
    final hasOutOfStockProducts = isOutOfStock && outOfStockCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: shouldShowColor
            ? (hasOutOfStockProducts
                  ? Colors.red.shade50
                  : Colors.green.shade50)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: shouldShowColor
            ? Border.all(
                color: hasOutOfStockProducts
                    ? Colors.red.shade300
                    : Colors.green.shade300,
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: shouldShowColor
                ? (hasOutOfStockProducts
                      ? Colors.red.shade700
                      : Colors.green.shade700)
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: shouldShowColor
                  ? (hasOutOfStockProducts
                        ? Colors.red.shade700
                        : Colors.green.shade700)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: shouldShowColor ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasOutOfStockProducts) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$outOfStockCount out of stock',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSubcategories(Category category) {
    final isSelectionMode =
        ModalRoute.of(context)?.settings.arguments as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${category.name} Subcategories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: category.subcategories.length,
                    itemBuilder: (context, index) {
                      final subcategory = category.subcategories[index];
                      final hasProducts = subcategory.productsCount > 0;
                      final hasOutOfStock = subcategory.outOfStockCount > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: hasProducts
                            ? (hasOutOfStock
                                  ? Colors.red.shade50
                                  : Colors.green.shade50)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: hasProducts
                              ? BorderSide(
                                  color: hasOutOfStock
                                      ? Colors.red.shade300
                                      : Colors.green.shade300,
                                  width: 1.5,
                                )
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: hasProducts
                                  ? (hasOutOfStock
                                        ? Colors.red.shade100
                                        : Colors.green.shade100)
                                  : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(subcategory.name),
                              color: hasProducts
                                  ? (hasOutOfStock
                                        ? Colors.red.shade700
                                        : Colors.green.shade700)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subcategory.name,
                                  style: TextStyle(
                                    fontWeight: hasProducts
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: hasOutOfStock
                                        ? Colors.red.shade900
                                        : null,
                                  ),
                                ),
                              ),
                              if (hasProducts && hasOutOfStock)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'OUT OF STOCK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subcategory.description != null)
                                Text(
                                  subcategory.description!,
                                  style: TextStyle(
                                    color: hasOutOfStock
                                        ? Colors.red.shade700
                                        : null,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 14,
                                    color: hasOutOfStock
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${subcategory.productsCount} products',
                                    style: TextStyle(
                                      color: hasOutOfStock
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (hasOutOfStock) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${subcategory.outOfStockCount} out of stock)',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: hasProducts
                              ? Icon(
                                  Icons.check_circle,
                                  color: hasOutOfStock
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                )
                              : null,
                          onTap: isSelectionMode
                              ? () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close bottom sheet
                                  Navigator.of(
                                    context,
                                  ).pop(subcategory); // Return to add product
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
