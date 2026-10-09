import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/colors.dart';
import '../../../../models/product.dart';
import '../../../../utils/localization_service.dart';

class ProductReelsScreen extends StatefulWidget {
  final Product product;
  const ProductReelsScreen({super.key, required this.product});

  @override
  State<ProductReelsScreen> createState() => _ProductReelsScreenState();
}

class _ProductReelsScreenState extends State<ProductReelsScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _scrollOffset = _pageController.offset;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              final itemPosition = index * MediaQuery.of(context).size.height;
              final parallaxOffset = (_scrollOffset - itemPosition) * 0.5;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Enhanced Parallax & Scale Image
                  Transform.translate(
                    offset: Offset(0, parallaxOffset),
                    child: Transform.scale(
                      scale: 1.1 + (parallaxOffset.abs() / 1000), // Dynamic zoom effect
                      child: Image.network(
                        widget.product.images[index],
                        fit: BoxFit.cover,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                  ),
                  
                  // Removed Diamond Glint Animation Overlay

                  // Dark Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.2, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Product Info Glassmorphic Overlay
                  Positioned(
                    bottom: 40,
                    right: 20,
                    left: 90, // Space for side actions
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'live_view_now'.tr(),
                                    style: GoogleFonts.cairo(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.product.name,
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.liquidGold,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primaryGold.withOpacity(0.3), blurRadius: 10),
                                  ],
                                ),
                                child: Text(
                                  'book_item_now'.tr(),
                                  style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Side Actions
          Positioned(
            bottom: 60,
            left: 20,
            child: Column(
              children: [
                _buildReelAction(Icons.favorite_rounded, '1.2k', Colors.red),
                const SizedBox(height: 24),
                _buildReelAction(Icons.share_rounded, 'share'.tr(), Colors.white),
                const SizedBox(height: 24),
                _buildReelAction(Icons.info_outline_rounded, 'details'.tr(), AppColors.primaryGold),
              ],
            ),
          ),
          // Back Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Scroll Indicator Instruction
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38),
                Text('swipe_up_for_more'.tr(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label, 
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}
