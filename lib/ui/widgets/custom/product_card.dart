import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../config/colors.dart';
import '../../../../models/product.dart';
import '../../../../state/favorites_state.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/localization_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showFavorite;

  const ProductCard({
    super.key, 
    required this.product, 
    this.onTap,
    this.showFavorite = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = context.watch<FavoritesState>();
    final isFav = favoritesState.isFavorite(widget.product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.matteBlack : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.product.mainImageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
                                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                child: Container(color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_not_supported_outlined, color: AppColors.primaryGold, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Mojohrti Pro',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 10,
                                          color: AppColors.primaryGold.withOpacity(0.5),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.product.availableStock <= 0)
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              'currently_unavailable'.tr(),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.showFavorite)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () {
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
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    if (widget.product.isFeatured)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.liquidGold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'royal'.tr(),
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.product.merchant != null) ...[
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                            backgroundImage: widget.product.merchant!.logoUrl.isNotEmpty 
                              ? NetworkImage(widget.product.merchant!.logoUrl) 
                              : null,
                            child: widget.product.merchant!.logoUrl.isEmpty 
                              ? const Icon(Icons.store, size: 10, color: AppColors.primaryGold) 
                              : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.product.merchant!.storeName,
                              style: GoogleFonts.cairo(
                                fontSize: 10, 
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.bold
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.scale_outlined, size: 10, color: AppColors.primaryGold),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.product.weight} ${'gram'.tr()}',
                            style: GoogleFonts.cairo(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.product.materialType.tr(),
                            style: GoogleFonts.cairo(fontSize: 9, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
}
