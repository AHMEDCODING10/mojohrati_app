import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/colors.dart';

class GoldGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const GoldGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 55,
    this.padding,
  });

  @override
  State<GoldGradientButton> createState() => _GoldGradientButtonState();
}

class _GoldGradientButtonState extends State<GoldGradientButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _isPressed = true);
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: (widget.isLoading || widget.onPressed == null) ? null : widget.onPressed,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: (widget.isLoading || widget.onPressed == null)
                ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                : AppColors.liquidGold,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.isLoading || widget.onPressed == null)
                    ? Colors.transparent 
                    : AppColors.primaryGold.withOpacity(_isHovered ? 0.4 : 0.2),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: Offset(0, _isHovered ? 6 : 4),
                ),
              ],
            ),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.black87, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ).animate(target: _isHovered ? 1 : 0)
       .shimmer(duration: 1.5.seconds, color: Colors.white.withOpacity(0.3)),
    );
  }
}
