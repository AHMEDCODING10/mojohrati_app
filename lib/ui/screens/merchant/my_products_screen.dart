import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/product_card.dart';
import '../customer/product_details_screen.dart';
import 'add_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  final Function(int)? onDrawerItemTap;
  final VoidCallback? onOpenDrawer;
  const MyProductsScreen({super.key, this.onDrawerItemTap, this.onOpenDrawer});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  String? _selectedCategoryId; // null = show category grid
  String _selectedMaterial = 'all'; // all, gold, silver, gemstone
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AppState>().fetchMerchantProducts();
      context.read<AppState>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    var list = products;
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((p) => 
        p.name.toLowerCase().contains(query) || 
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    // Filter by material
    if (_selectedMaterial != 'all') {
      list = list.where((p) => p.materialType == _selectedMaterial).toList();
    }

    // Filter by Out of Stock (Reactive from AppState)
    if (context.read<AppState>().showOnlyOutOfStock) {
      list = list.where((p) => (p.stockQuantity ?? 0) <= 0).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allProducts = appState.products;
    final filteredProducts = _getFilteredProducts(allProducts);
    final allCategories = appState.categories;

    // Find selected category name for the title
    String title = 'product_vault'.tr();
    if (_selectedCategoryId != null) {
      try {
        if (_selectedCategoryId == '__uncategorised__') {
          title = 'غير مصنف';
        } else {
          title = allCategories
              .firstWhere((c) => c['id'].toString() == _selectedCategoryId)['name'];
        }
      } catch (_) {}
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _selectedCategoryId != null || _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryGold),
                onPressed: () {
                  setState(() {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                    } else {
                      _selectedCategoryId = null;
                    }
                  });
                },
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.primaryGold, size: 28),
                  onPressed: () {
                    if (widget.onOpenDrawer != null) {
                      widget.onOpenDrawer!();
                    } else {
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                ),
              ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPremiumSearchBar(isDark),
              _buildMaterialTabs(isDark),
              if (appState.showOnlyOutOfStock) _buildStatusFilterChip(appState, isDark),
              const SizedBox(height: 16),
              Expanded(
                child: appState.isLoading && allProducts.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                    : (_searchController.text.isNotEmpty || _selectedMaterial != 'all'
                        ? _buildProductsGrid(context, appState, filteredProducts, isDark)
                        : (_selectedCategoryId == null
                            ? _buildCategoryGrid(context, allCategories, filteredProducts, isDark)
                            : _buildProductsGrid(context, appState, 
                                filteredProducts.where((p) {
                                  if (_selectedCategoryId == '__uncategorised__') {
                                    final knownIds = allCategories.map((c) => c['id'].toString()).toSet();
                                    return !knownIds.contains(p.categoryId.toString());
                                  }
                                  return p.categoryId.toString() == _selectedCategoryId;
                                }).toList(), 
                                isDark))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildPremiumSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'search_placeholder'.tr(),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        ),
      ),
    );
  }

  // ── Material Tabs ──────────────────────────────────────────────────────────
  Widget _buildMaterialTabs(bool isDark) {
    final materials = [
      {'id': 'all', 'name': 'all_products'.tr(), 'icon': Icons.grid_view_rounded},
      {'id': 'gold', 'name': 'gold'.tr(), 'icon': Icons.layers_rounded},
      {'id': 'silver', 'name': 'silver'.tr(), 'icon': Icons.auto_awesome_rounded},
      {'id': 'gemstone', 'name': 'gemstone'.tr(), 'icon': Icons.diamond_outlined},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final m = materials[index];
          final id = m['id'] as String;
          final isSelected = _selectedMaterial == id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMaterial = id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.liquidGold : null,
                color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.primaryGold.withOpacity(0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Row(
                children: [
                   Icon(m['icon'] as IconData, size: 16, color: isSelected ? Colors.black87 : AppColors.primaryGold),
                   const SizedBox(width: 8),
                   Text(
                    m['name'] as String,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Category Grid View ──────────────────────────────────────────────────────
  Widget _buildCategoryGrid(
    BuildContext context,
    List<dynamic> categories,
    List<dynamic> filteredProducts,
    bool isDark,
  ) {
    final categoriesWithProducts = categories.where((c) {
      final catId = c['id'].toString();
      return filteredProducts.any((p) {
        final prodCatId = p.categoryId?.toString() ?? '';
        return prodCatId == catId;
      });
    }).toList();

    if (categoriesWithProducts.isEmpty && filteredProducts.isNotEmpty) {
       // FALLBACK: If we have products but no matching categories, show products directly
       return _buildProductsGrid(context, context.read<AppState>(), filteredProducts, isDark);
    }

    if (categoriesWithProducts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            'categories'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categoriesWithProducts.length,
            itemBuilder: (context, index) {
              final cat = categoriesWithProducts[index];
              final catId = cat['id'].toString();
              final count = filteredProducts.where((p) => p.categoryId.toString() == catId).length;
              return _MerchantCategoryCard(
                name: cat['name'] ?? '',
                imageUrl: cat['image_url'],
                count: count,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategoryId = catId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Products Grid ──────────────────────────────────────────────────────────
  Widget _buildProductsGrid(
    BuildContext context,
    AppState appState,
    List<dynamic> products,
    bool isDark,
  ) {
    if (products.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.primaryGold.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('no_products_found'.tr(),
                  style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isOutOfStock = (product.stockQuantity ?? 0) <= 0;
        
        return Stack(
          children: [
            Opacity(
              opacity: isOutOfStock ? 0.7 : 1.0,
              child: ProductCard(
                product: product,
                showFavorite: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product)),
                ),
              ),
            ),
            // Actions are handled by Positioned widgets below
            Positioned(
              top: 8,
              left: 8,
              child: _ActionButton(
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                onTap: () => _confirmDelete(context, product.id, appState),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _ActionButton(
                icon: Icons.edit_rounded,
                color: AppColors.primaryGold,
                iconColor: Colors.black,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddProductScreen(product: product)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('vault_empty'.tr(),
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(AppState appState, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  'تصفية: المنتجات المنتهية',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => appState.setShowOnlyOutOfStock(false),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text('عرض الكل', style: GoogleFonts.cairo(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String productId, AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.matteBlack
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('confirm_delete_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('confirm_delete_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('delete_item_btn'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await appState.deleteProduct(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'product_delete_success'.tr()
            : 'product_delete_failed'.tr()),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (success) appState.fetchMerchantProducts();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _MerchantCategoryCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _MerchantCategoryCard({
    required this.name,
    this.imageUrl,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForCategory(name),
                        color: AppColors.primaryGold,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count ${'items'.tr()}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    name = name.toLowerCase();
    if (name.contains('خواتم') || name.contains('ring')) return Icons.diamond;
    if (name.contains('سلاسل') || name.contains('chain') || name.contains('neck')) return Icons.layers_outlined;
    if (name.contains('أساور') || name.contains('bracelet')) return Icons.circle_outlined;
    if (name.contains('حزام') || name.contains('belt')) return Icons.horizontal_rule_rounded;
    return Icons.auto_awesome_rounded;
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2E), AppColors.matteBlack]
              : [AppColors.royalCream, const Color(0xFFE8D5A3)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_rounded,
                color: AppColors.primaryGold.withOpacity(0.5), size: 36),
          ],
        ),
      ),
    );
  }
}
