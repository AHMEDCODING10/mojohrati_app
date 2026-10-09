import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'product_details_screen.dart';
import '../../../config/colors.dart';
import '../../../models/product.dart';
import '../../../state/app_state.dart';
import '../../widgets/custom/product_card.dart';
import '../../../utils/localization_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/constants.dart';

class StoreProfileScreen extends StatefulWidget {
  final MerchantData merchant;

  const StoreProfileScreen({super.key, required this.merchant});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  List<Product> _merchantProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    // Fetch products for this specific merchant on entry using the new scoped method
    _loadMerchantProducts();
  }

  Future<void> _loadMerchantProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);
    
    final products = await context.read<AppState>().fetchProductsByMerchant(widget.merchant.id);
    
    if (mounted) {
      setState(() {
        _merchantProducts = products;
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final featuredProducts = _merchantProducts.where((p) => p.isFeatured).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, isDark),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildStoreHeader(isDark),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              ),

              // Featured Products Section
              if (featuredProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'featured_piece'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final product = featuredProducts[index];
                        return SizedBox(
                          width: 180,
                          child: ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          ),
                        ).animate(delay: (index * 100).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                      },
                    ),
                  ),
                ),
              ],

              // All Products Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'my_products'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${_merchantProducts.length} ${'products_count'.tr()}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoadingProducts && _merchantProducts.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                )
              else if (_merchantProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'no_products'.tr(),
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _merchantProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product),
                            ),
                          ),
                        ).animate(delay: (index * 50).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                      },
                      childCount: _merchantProducts.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? AppColors.matteBlack : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Store Banner/Logo as background
            widget.merchant.logoUrl.isNotEmpty 
              ? Image.network(widget.merchant.logoUrl, fit: BoxFit.cover)
              : Image.asset(AppConstants.placeholderImage, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    isDark ? AppColors.matteBlack.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Store Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primaryGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            image: widget.merchant.logoUrl.isNotEmpty 
              ? DecorationImage(image: NetworkImage(widget.merchant.logoUrl), fit: BoxFit.cover)
              : null,
          ),
          child: widget.merchant.logoUrl.isEmpty 
            ? const Icon(Icons.store_rounded, color: AppColors.primaryGold, size: 40)
            : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.merchant.storeName,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    widget.merchant.address,
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSocialButtons(widget.merchant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(MerchantData merchant) {
    return Row(
      children: [
        _buildSmallIconBtn(Icons.chat_bubble_outline_rounded, () async {
          final whatsapp = merchant.whatsapp;
          if (whatsapp.isNotEmpty) {
            await launchUrl(Uri.parse("https://wa.me/$whatsapp"), mode: LaunchMode.externalApplication);
          }
        }),
        const SizedBox(width: 12),
        _buildSmallIconBtn(Icons.phone_outlined, () async {
          final phone = merchant.contactNumber ?? merchant.whatsapp;
          if (phone.isNotEmpty) {
            await launchUrl(Uri.parse("tel:$phone"));
          }
        }),
        const SizedBox(width: 12),
        _buildSmallIconBtn(Icons.share_outlined, () {
           final url = 'https://mojowharati-app.web.app/store/${merchant.id}';
           Share.share('${'check_out_store'.tr()} ${merchant.storeName}\n\n$url');
        }),
      ],
    );
  }

  Widget _buildSmallIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 16),
      ),
    );
  }
}
