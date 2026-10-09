import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/colors.dart';
import '../../../../models/product.dart';
import '../../../../utils/localization_service.dart';
import '../../../../config/constants.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final Product product;
  const VirtualTryOnScreen({super.key, required this.product});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> with TickerProviderStateMixin {
  double _ringScale = 0.6;
  double _ringRotation = 0.0;
  Offset _ringPosition = const Offset(0, 0);
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _scannerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut));
    
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera View (Using a luxury hand placeholder)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.placeholderImage), 
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Technical Overlay
          CustomPaint(
            painter: _ScannerGridPainter(),
            child: Container(),
          ),

          // Futuristic AR Scanner Overlay
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Positioned(
                top: (MediaQuery.of(context).size.height / 2) + (_scannerAnimation.value * 300),
                left: 0,
                right: 0,
                child: _buildScannerLine(),
              );
            },
          ),

          // Instruction Text
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: _buildHeaderInfo(),
          ),

          // Interactive Product Overlay
          Center(
            child: Transform.translate(
              offset: _ringPosition,
              child: Transform.rotate(
                angle: _ringRotation,
                child: Transform.scale(
                  scale: _ringScale,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _ringPosition += details.delta;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withValues(alpha: 0.15 * _glowController.value), 
                                    blurRadius: 50 + (20 * _glowController.value), 
                                    spreadRadius: 10
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Hero(
                          tag: 'product_try_on_${widget.product.id}',
                          child: Image.network(
                            widget.product.images.first,
                            width: 280,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls (Scale & Rotation)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: _buildControls(context),
          ),

          // Back Button
          Positioned(
            top: 55,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerLine() {
    return Column(
      children: [
        Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(color: AppColors.primaryGold, blurRadius: 15, spreadRadius: 1),
            ],
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primaryGold.withValues(alpha: 0.5),
                AppColors.primaryGold,
                AppColors.primaryGold.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPulsingDot(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'try_on'.tr(),
                style: GoogleFonts.playfairDisplay(color: AppColors.primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'precise_tracking'.tr(),
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.5 * _glowController.value), blurRadius: 8, spreadRadius: 2 * _glowController.value),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlRow(Icons.zoom_in_rounded, _ringScale, (v) => setState(() => _ringScale = v), 0.2, 1.5),
              const SizedBox(height: 16),
              _buildControlRow(Icons.rotate_right_rounded, _ringRotation, (v) => setState(() => _ringRotation = v), -3.14, 3.14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow(IconData icon, double value, Function(double) onChanged, double min, double max) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.primaryGold,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ScannerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGold.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
