// ignore_for_file: unused_element, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../widgets/custom/product_card.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/error_state.dart';
import '../../../utils/localization_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  String? _selectedSubCategoryId;
  String? _selectedMerchantId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchMerchants();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 500 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 500 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }

    // Proactive Infinite Scroll Logic (Prefetching)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) {
      context.read<AppState>().fetchProducts(categoryId: widget.categoryId, loadMore: true);
    }
  }

  void _scrollToTop() {
    HapticFeedback.mediumImpact();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> _refresh() async {
    await context.read<AppState>().fetchProducts(
      categoryId: _selectedSubCategoryId ?? widget.categoryId,
      merchantId: _selectedMerchantId,
    );
  }

  void _onSubCategorySelected(String? id) {
    HapticFeedback.lightImpact();
    setState(() => _selectedSubCategoryId = id);
    _refresh();
  }

  void _onMerchantSelected(String? id) {
    HapticFeedback.lightImpact();
    setState(() => _selectedMerchantId = id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    
    final appState = context.watch<AppState>();
    final products = appState.products;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryGold,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (appState.isSlowConnection)
                SliverToBoxAdapter(child: _buildSlowConnectionWarning()),
              // Premium Header
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    widget.categoryName,
                    style:GoogleFonts.playfairDisplay(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              
              // Merchant Filter
              _buildMerchantFilter(appState, isDark),

              // Product Grid
              if (appState.isLoading && products.isEmpty)
                SliverToBoxAdapter(child: LoadingShimmer.grid(crossAxisCount: crossAxisCount))
              else if (appState.error != null && products.isEmpty)
                SliverFillRemaining(
                  child: ErrorState(
                    message: appState.error!,
                    onRetry: _refresh,
                  ),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: 'no_products'.tr(),
                    message: 'no_products_desc'.tr(),
                    icon: Icons.search_off_rounded,
                    onAction: () {
                      setState(() {
                        _selectedSubCategoryId = null;
                        _selectedMerchantId = null;
                      });
                      _refresh();
                    },
                    actionLabel: 'reset_filters'.tr(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(product: products[index]);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
              if (appState.isFetchingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTop ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up_rounded),
      ) : null,
    );
  }

  Widget _buildMerchantFilter(AppState appState, bool isDark) {
    final merchants = appState.merchants;
    if (merchants.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'suggested_merchants'.tr(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 54,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.1),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: merchants.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                final isAll = index == 0;
                final merchant = isAll ? null : merchants[index - 1];
                final id = isAll ? null : merchant['id'].toString();
                final name = isAll ? 'all_merchants'.tr() : merchant['name'];
                final isSelected = _selectedMerchantId == id;

                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (_) => _onMerchantSelected(id),
                  selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
                  backgroundColor: Colors.transparent,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white70 : Colors.black54),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  ],
),
);
}

  Widget _buildSlowConnectionWarning() {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'slow_connection_alert'.tr(),
              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}