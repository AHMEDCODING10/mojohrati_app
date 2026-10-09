import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../widgets/custom/product_card.dart';
import '../../widgets/shared/drawer.dart';
import 'product_details_screen.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/error_state.dart';
import '../../widgets/custom/integrated_header.dart';
import 'misc_screens.dart';
import '../../../models/product.dart';
import '../../../utils/localization_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
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
      context.read<AppState>().fetchProducts(loadMore: true);
    }
  }

  void _scrollToTop() {
    HapticFeedback.mediumImpact();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> _refreshData() async {
    final appState = context.read<AppState>();
    await Future.wait([
      appState.fetchProducts(),
      appState.fetchCategories(),
      appState.fetchBanners(placement: 'home_top'),
      appState.fetchNotifications(),
    ]);
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryGold,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 185,
              collapsedHeight: 185,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              backgroundColor: isDark ? AppColors.matteBlack : AppColors.royalCream,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: IntegratedHeroHeader(
                  onSearchTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GramSearchScreen())),
                ),
                collapseMode: CollapseMode.pin,
              ),
            ),
            SliverToBoxAdapter(
               child: Column(
                children: [
                  const IntegratedSearchBar(),
                  const SizedBox(height: 16),
                  if (appState.isSlowConnection)
                    _buildSlowConnectionWarning(isDark),
                  _buildPromoSlider(appState.getBannersByPlacement('home_top')),
                  _buildFeaturedProducts(isDark, appState),
                  const SizedBox(height: 24),
                  _buildBentoProductGrid(isDark, appState),

                  const SizedBox(height: 24),
                  if (appState.isFetchingMore)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
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

  Widget _buildPromoSlider(List<dynamic> banners, {double height = 160}) {
    if (banners.isEmpty) return const SizedBox.shrink();


    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: height,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.95,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: banners.map((banner) {

            final String? imageUrl = banner['image_url'];
            final String? videoUrl = banner['video_url'];
            final String? link = banner['link'];
            final bool isVideo = banner['type'] == 'video';
            
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final targetUrl = isVideo ? videoUrl : link;
                if (targetUrl != null && targetUrl.isNotEmpty) {
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('opening_link'.tr()),
                         duration: const Duration(seconds: 1),
                         backgroundColor: AppColors.primaryGold,
                       ),
                     );
                  }

                  final uri = Uri.parse(targetUrl);
                  try {
                    // Try to launch directly which is more compatible with Web
                    final launched = await launchUrl(
                      uri, 
                      mode: LaunchMode.platformDefault,
                    );
                    
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('could_not_open_url'.tr())),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error launching URL: $e');
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('error_opening_url'.tr())),
                      );
                    }
                  }
                }
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black87,
                  image: imageUrl != null && imageUrl.isNotEmpty ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: isVideo ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken) : null,
                  ) : null,
                  gradient: (imageUrl == null || imageUrl.isEmpty) ? const LinearGradient(
                    colors: [AppColors.matteBlack, Color(0xFF1A1A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (isVideo)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGold.withOpacity(0.8),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
                        ),
                      ),
                    
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isVideo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VIDEO',
                                style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                          Text(
                            banner['title'] ?? '',
                            style: GoogleFonts.cairo(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 18,
                              shadows: [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onTap, child: Text('view_all'.tr(), style: const TextStyle(color: AppColors.primaryGold))),
      ],
    );
  }





  Widget _buildBentoProductGrid(bool isDark, AppState appState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    if (appState.isLoading && appState.products.isEmpty) {
      return LoadingShimmer.grid(crossAxisCount: crossAxisCount);
    }

    if (appState.error != null && appState.products.isEmpty) {
      return ErrorState(
        message: appState.error!,
        onRetry: _refreshData,
      );
    }

    if (appState.products.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text('no_products_found'.tr(), style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'curated_collections'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${appState.products.length} ${'piece'.tr()}',
                style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (appState.isLoading && appState.products.isEmpty)
          LoadingShimmer.grid(count: 4)
        else if (appState.products.isEmpty)
          EmptyState(
            title: 'no_products'.tr(),
            message: 'no_products_desc'.tr(),
            onAction: () {
              appState.fetchProducts();
            },
            actionLabel: 'reset_search'.tr(),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.72, // Consistent with categories screen
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: appState.products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: appState.products[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(product: appState.products[index]),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // Removed _buildSearchBar as it is now in the IntegratedHeroHeader

  Widget _buildFeaturedProducts(bool isDark, AppState appState) {
    // Only show products explicitly marked as featured by admin
    final List<Product> featured = appState.featuredProducts;
        
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildSectionHeader('featured_products'.tr(), () {
            // Navigate to all products or a specific featured category if available
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 270, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: featured.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(left: 16),
                child: ProductCard(
                  product: featured[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: featured[index]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildSlowConnectionWarning(bool isDark) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withOpacity(0.1),
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
