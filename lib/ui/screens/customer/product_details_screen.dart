// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, avoid_unnecessary_containers
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../models/product.dart';
import '../../../state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../state/cart_state.dart';
import '../../../state/favorites_state.dart';
import '../../../utils/localization_service.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom/full_screen_viewer.dart';
import '../auth/auth_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/review.dart';
import '../../widgets/custom/gold_gradient_button.dart';
import 'store_profile_screen.dart';
import '../../widgets/shared/reservation_bag_icon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:dio/dio.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  bool _showAllReviews = false;
  int _selectedQuantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchProductReviews(widget.product.id);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _shareProduct() async {
      final name = widget.product.name;
      final desc = widget.product.description;
      final url = 'https://mojowharati-app.web.app/product/${widget.product.id}';
      
      final shareMessage = "${'check_out_masterpiece'.tr()}\n\n"
                           "$name\n\n"
                           "$desc\n\n"
                           "$url";
      
      try {
        final imagePath = await _downloadProductImage();
        if (imagePath != null) {
          await Share.shareXFiles([XFile(imagePath)], text: shareMessage);
        } else {
          await Share.share(shareMessage);
        }
      } catch (e) {
        await Share.share(shareMessage);
      }
  }

  Future<String?> _downloadProductImage() async {
    if (widget.product.images.isEmpty) return null;
    try {
      final dio = Dio();
      final url = widget.product.images.first;
      final tempDir = await getTemporaryDirectory();
      
      // Get a safe extension or fallback to jpg
      String extension = p.extension(url).split('?').first;
      if (extension.isEmpty) extension = '.jpg';
      
      final filePath = "${tempDir.path}/prod_${widget.product.id}$extension";
      
      // Check if already exists to avoid re-downloading during same session
      if (await File(filePath).exists()) return filePath;
      
      await dio.download(url, filePath);
      return filePath;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }


  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('product_qr_code'.tr(), 
           style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
           textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: QrImageView(
                  data: '${AppConstants.publicBaseUrl}/p/${widget.product.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: AppColors.primaryGold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'https://mojowharati-app.web.app/product/${widget.product.id}',
              style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('close'.tr(), style: GoogleFonts.cairo(color: AppColors.primaryGold))
          ),
        ],
      ),
    );

  }

  Future<void> _contactMerchant() async {
    final whatsapp = widget.product.merchant?.whatsapp;
    if (whatsapp == null) return;
    
    final imgUrl = widget.product.images.isNotEmpty ? widget.product.images.first : "";
    
    final message = "السلام عليكم، أنا مهتم بهذه القطعة: ${widget.product.name}\n"
                    "${imgUrl.isNotEmpty ? '$imgUrl\n' : ''}"
                    "هل هي متوفرة؟";
    
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse("https://wa.me/$whatsapp?text=$encodedMessage");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = context.watch<FavoritesState>();
    final appState = context.watch<AppState>();
    final isFav = favoritesState.isFavorite(widget.product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMerchant = appState.currentUser?.type == 'merchant';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isFav, favoritesState, 0.0, '', isMerchant),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (widget.product.viewsCount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      size: 14,
                                      color: isDark ? Colors.white38 : Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.product.viewsCount} ${'مشاهدة'}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Case 1: Gemstones - Show multi-row detailed specs
                  if (widget.product.materialType == 'gemstone') ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.scale_rounded,
                            title: 'gold_weight_label'.tr(),
                            value: '${widget.product.weight} ${'gram'.tr()}'
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.diamond_outlined,
                            title: 'stone_type'.tr(),
                            value: (widget.product.stoneType != null && widget.product.stoneType!.isNotEmpty) 
                                ? widget.product.stoneType! 
                                : '-'
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.monitor_weight_outlined,
                            title: 'stone_weight_label'.tr(),
                            value: (widget.product.stoneWeight != null && widget.product.stoneWeight! > 0) 
                                ? '${widget.product.stoneWeight} ${'gram'.tr()}' 
                                : '-'
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.visibility_outlined,
                            title: 'clarity'.tr(),
                            value: (widget.product.clarity != null && widget.product.clarity!.isNotEmpty) 
                                ? widget.product.clarity! 
                                : '-'
                          ),
                        ),
                      ],
                    ),
                    if (widget.product.cut != null || widget.product.materialType == 'gemstone') ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.architecture_rounded,
                        title: 'cut'.tr(),
                        value: (widget.product.cut != null && widget.product.cut!.isNotEmpty) 
                            ? widget.product.cut! 
                            : '-'
                      ),
                    ],
                  ] 
                  // Case 2: Gold/Silver - Show standard specs
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.scale_rounded,
                            title: 'weight_gram'.tr(),
                            value: '${widget.product.weight} ${'gram'.tr()}'
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.workspace_premium_rounded,
                            title: widget.product.materialType == 'gold' ? 'purity'.tr() : 'silver_purity'.tr(),
                            value: widget.product.purity ?? widget.product.materialName
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    'description'.tr(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description,
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Store card
                  if (widget.product.merchant != null)
                    _buildStoreCard(widget.product.merchant!),
                  const SizedBox(height: 32),
                  
                  // Customer Actions
                  if (!isMerchant) ...[
                    const SizedBox(height: 16),
                    if (widget.product.availableStock <= 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'out_of_stock_msg'.tr(),
                                style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GoldGradientButton(
                            text: 'add_to_cart'.tr(),
                            onPressed: widget.product.availableStock <= 0 ? null : () {
                              context.read<CartState>().addItem(widget.product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('add_to_cart'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    GoldGradientButton(
                      text: widget.product.availableStock <= 0 ? 'currently_unavailable'.tr() : 'book_now'.tr(),
                      onPressed: widget.product.availableStock <= 0 ? null : () {
                        final appState = context.read<AppState>();
                        if (!appState.isLoggedIn) {
                          _showLoginRequiredDialog();
                        } else {
                          _showBookingDialog();
                        }
                      },
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 48),
                  ],

                  // Common sections
                  _buildReviewsSection(isDark, appState),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isFav, FavoritesState favoritesState, double price, String currency, bool isMerchant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 550,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.matteBlack : AppColors.royalCream,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (widget.product.images.isEmpty)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: isDark 
                    ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey[900]!, Colors.black])
                    : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey[100]!, Colors.grey[200]!]),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'no_product_images'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
            CarouselSlider(
              options: CarouselOptions(
                height: 550,
                viewportFraction: 1.0,
                autoPlay: widget.product.images.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: widget.product.images.length > 1,
                onPageChanged: (index, reason) => setState(() => _currentImageIndex = index),
              ),
              items: widget.product.images.asMap().entries.map((entry) {
                final index = entry.key;
                final img = entry.value;
                return GestureDetector(
                  onTap: () => _openFullScreenViewer(index),
                  child: Hero(
                    tag: 'product_image_${widget.product.id}_$index',
                    child: CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'جاري تحميل الصورة...',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, err) => Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'تعذر تحميل الصورة',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Positioned(
              bottom: 30,
              right: 0,
              left: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.product.images.asMap().entries.map((entry) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == entry.key ? AppColors.primaryGold : Colors.white60,
                    ),
                  );
                }).toList(),
              ),
            ),
            if (widget.product.availableStock <= 0)
              Positioned(
                top: 100,
                left: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Text(
                    'currently_unavailable'.tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, 
                 color: isFav ? Colors.red : Colors.white, size: 20),
            onPressed: () {
            HapticFeedback.lightImpact();
            favoritesState.toggleFavorite(widget.product.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !isFav ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                backgroundColor: !isFav ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 4),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              _shareProduct();
            },
          ),
      ),
      const SizedBox(width: 4),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
            onPressed: _showQRCode,
          ),
      ),
        if (!isMerchant) ...[
          const ReservationBagIcon(isDark: true, iconColor: Colors.white),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildStoreCard(MerchantData merchant) {
    final appState = context.read<AppState>();
    final isOwnProduct = appState.currentUser?.merchantId != null && 
                        merchant.id == appState.currentUser!.merchantId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreProfileScreen(merchant: merchant),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.royalCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGold, width: 0.5),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: merchant.logoUrl.isNotEmpty 
                  ? NetworkImage(merchant.logoUrl) 
                  : const AssetImage(AppConstants.logoPlaceholder) as ImageProvider,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwnProduct ? 'التفاصيل من متجر' : 'اطلب الآن من متجر',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  merchant.storeName,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!isOwnProduct) ...[
            IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.primaryGold),
              onPressed: () async {
                final phone = widget.product.merchant?.contactNumber ?? '';
                if (phone.isNotEmpty) {
                  await launchUrl(Uri.parse("tel:$phone"));
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGold),
              onPressed: _contactMerchant,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ],
      ),
     ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.royalCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // Removed unused sizing guide method

  void _showBookingDialog() {
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn || appState.currentUser?.type == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('guest_restriction_msg'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.matteBlack.withValues(alpha: 0.8) 
                    : AppColors.royalCream.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with Glow
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGold.withValues(alpha: 0.2),
                              AppColors.primaryGold.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded, 
                          color: AppColors.primaryGold, 
                          size: 56
                        ),
                      ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'confirm_booking_title'.tr(),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'confirm_booking_desc'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Quantity Picker
                      if (widget.product.manageStock)
                        StatefulBuilder(
                          builder: (context, setModalState) {
                            return Column(
                              children: [
                                Text(
                                  'choose_quantity'.tr().isNotEmpty ? 'choose_quantity'.tr() : 'اختر الكمية المطلوبة:',
                                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildQtyBtn(Icons.remove, () {
                                      if (_selectedQuantity > 1) {
                                        setModalState(() => _selectedQuantity--);
                                        setState(() {});
                                      }
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        '$_selectedQuantity',
                                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildQtyBtn(Icons.add, () {
                                      if (_selectedQuantity < widget.product.stockQuantity) {
                                        setModalState(() => _selectedQuantity++);
                                        setState(() {});
                                      }
                                    }, isDisabled: _selectedQuantity >= widget.product.stockQuantity),
                                  ],
                                ),
                                if (_selectedQuantity >= widget.product.stockQuantity)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'max_available_stock'.tr().isNotEmpty ? 'max_available_stock'.tr() : 'وصلت للحد الأقصى المتاح',
                                      style: const TextStyle(color: Colors.orange, fontSize: 10),
                                    ),
                                  ),
                              ],
                            );
                          }
                        ).animate().fadeIn(delay: 350.ms),
                      
                      const SizedBox(height: 20),

                      // Customer Notes Field
                      StatefulBuilder(
                        builder: (ctx, _) => TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'ملاحظة خاصة للتاجر (اختياري)',
                            hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primaryGold, size: 20),
                            filled: true,
                            fillColor: AppColors.primaryGold.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 380.ms),

                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'cancel'.tr(), 
                                style: GoogleFonts.cairo(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: GoldGradientButton(
                              text: 'confirm_booking_btn'.tr(),
                              onPressed: () {
                                Navigator.pop(context);
                                _processBooking();
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
    );
  }

  Widget _buildReviewsSection(bool isDark, AppState appState) {
    final isMerchant = appState.currentUser?.type == 'merchant';
    final reviews = appState.getProductReviews(widget.product.id);
    final isLoading = appState.isLoadingReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'reviews_title'.tr(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (appState.isLoggedIn && !isMerchant)
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showAddReviewSheet();
                },
                icon: const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.primaryGold),
                label: Text('add_review'.tr(), style: GoogleFonts.cairo(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
        else if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'no_reviews_yet'.tr(),
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Text(
                widget.product.averageRating.toStringAsFixed(1),
                style: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   RatingBarIndicator(
                    rating: widget.product.averageRating,
                    itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.product.reviewsCount} ${'reviews_count'.tr()}',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...reviews.take(_showAllReviews ? reviews.length : 3).map((r) => _buildReviewCard(r, isDark)),
          if (reviews.length > 3 && !_showAllReviews)
             Center(
               child: TextButton(
                 onPressed: () {
                    setState(() {
                      _showAllReviews = true;
                    });
                 },
                 child: Text('view_all_reviews'.tr(), style: GoogleFonts.cairo(color: AppColors.primaryGold)),
               ),
             ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Review review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.2),
                child: Text(review.userName[0], style: const TextStyle(color: AppColors.primaryGold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 12.0,
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
              ),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet() {
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.matteBlack : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('rate_this_product'.tr(), style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => selectedRating = rating,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'write_your_comment_hint'.tr(),
                hintStyle: GoogleFonts.cairo(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 24),
            GoldGradientButton(
              text: 'submit_review'.tr(),
              onPressed: () async {
                if (commentController.text.isEmpty) return;
                
                final success = await context.read<AppState>().addProductReview(
                  widget.product.id,
                  selectedRating,
                  commentController.text,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('review_submitted_success'.tr()), backgroundColor: Colors.green),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGold, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'تسجيل الدخول مطلوب',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يجب تسجيل الدخول لإتمام عملية الحجز.\nسجّل دخولك الآن للاستفادة من جميع المزايا.',
              style: GoogleFonts.cairo(fontSize: 14, height: 1.6, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('لاحقاً', style: GoogleFonts.cairo(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GoldGradientButton(
                    text: 'تسجيل الدخول',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processBooking() async {
    final appState = context.read<AppState>();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final errorMsg = await appState.requestBooking(
      int.tryParse(widget.product.id) ?? 0,
      quantity: _selectedQuantity,
      notes: notes,
    );
    
    if (mounted) {
      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('booking_success'.tr()), backgroundColor: Colors.green),
        );
      } else {
        // تحديد إذا كان الخطأ بسبب الحجز المسبق
        final isAlreadyBooked = errorMsg.contains('محجوز') || 
            errorMsg.contains('booked') || 
            errorMsg.contains('reserved') ||
            errorMsg.contains('حجز');
        
        final displayMsg = isAlreadyBooked
            ? 'هذا المنتج محجوز بالفعل. يمكنك تصفح المنتجات الأخرى أو التواصل مع المتجر مباشرة.'
            : errorMsg;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openFullScreenViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductGalleryViewer(
          images: widget.product.images,
          initialIndex: index,
          heroTag: 'product_image_${widget.product.id}',
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: isDisabled ? 0.1 : 0.5)),
          borderRadius: BorderRadius.circular(10),
          color: isDisabled ? Colors.grey.withValues(alpha: 0.05) : null,
        ),
        child: Icon(icon, size: 18, color: isDisabled ? Colors.grey : AppColors.primaryGold),
      ),
    );
  }
}