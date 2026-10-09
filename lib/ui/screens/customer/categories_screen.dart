import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/product_card.dart';
import 'product_details_screen.dart';
import '../../widgets/shared/reservation_bag_icon.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedMaterial = 'all'; // all, gold, silver, gemstone
  String _selectedCategoryId = 'all';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchProducts();
      context.read<AppState>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        context.read<AppState>().fetchProducts(search: _searchController.text);
      }
    });
  }

  void _loadFilteredProducts() {
    final appState = context.read<AppState>();
    appState.fetchProducts(
      categoryId: _selectedCategoryId == 'all' ? null : _selectedCategoryId,
      materialType: _selectedMaterial == 'all' ? null : _selectedMaterial,
      isRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final filteredProducts = state.products;
    final allCategories = state.categories;

    String currentTitle = 'store_categories'.tr();
    if (_selectedCategoryId != 'all') {
      try {
        currentTitle = allCategories.firstWhere((c) => c['id'].toString() == _selectedCategoryId)['name'];
      } catch (e) {
        currentTitle = 'all_products'.tr();
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.matteBlack : Colors.white,
      appBar: AppBar(
        title: Text(currentTitle),
        leading: _selectedCategoryId != 'all' 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => setState(() {
                 _selectedCategoryId = 'all';
                 _selectedMaterial = 'all'; 
                 _loadFilteredProducts();
              }),
            )
          : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ReservationBagIcon(isDark: isDark),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: Column(
          children: [
            _buildPremiumSearchBar(isDark),
            _buildMaterialTabs(isDark),
            const SizedBox(height: 16),
            Expanded(
              child: _searchController.text.isNotEmpty
                ? _buildSearchResults(context, state, isDark)
                : (_selectedCategoryId == 'all' 
                    ? _buildUniversalCategoryGrid(context, allCategories, state.products, isDark)
                    : _buildProductFilterView(context, state, filteredProducts, isDark)),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildMaterialTabs(bool isDark) {
    final materials = [
      {'id': 'all', 'name': 'all_products'.tr(), 'icon': Icons.grid_view_rounded},
      {'id': 'gold', 'name': 'gold'.tr(), 'icon': Icons.layers_rounded},
      {'id': 'silver', 'name': 'silver'.tr(), 'icon': Icons.auto_awesome_rounded},
      {'id': 'gemstone', 'name': 'gemstone'.tr(), 'icon': Icons.diamond_outlined},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
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
              setState(() {
                 _selectedMaterial = id;
                 _loadFilteredProducts();
              });
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

  Widget _buildUniversalCategoryGrid(BuildContext context, List<dynamic> categories, List<dynamic> products, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            'categories'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final id = category['id'].toString();
              final name = category['name'] ?? '';
              final imageUrl = category['image_url'];
              
              final realCount = int.tryParse(category['products_count']?.toString() ?? '0') ?? 0;

              return _CategoryVisualCard(
                name: name,
                imageUrl: imageUrl,
                count: realCount,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                     _selectedCategoryId = id;
                     _loadFilteredProducts();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductFilterView(BuildContext context, AppState state, List<dynamic> products, bool isDark) {
    if (state.isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.primaryGold.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'no_products_found'.tr(),
              style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, AppState state, bool isDark) {
    if (state.isLoading) {
       return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }
    
    final products = state.products;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.primaryGold.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'no_products_found'.tr(),
              style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryVisualCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryVisualCard({
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
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
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getIconForCategory(name),
                    color: AppColors.primaryGold,
                    size: 14,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$count عنصر',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: isDark ? AppColors.matteBlack : AppColors.royalCream,
      child: Center(
        child: Icon(Icons.category_outlined, color: AppColors.primaryGold.withOpacity(0.3), size: 40),
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
}
