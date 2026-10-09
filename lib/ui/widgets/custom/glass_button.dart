import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final Color? color;
  final IconData? icon;

  const GlassButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width,
    this.height = 55,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: 0.25), // Increased from 0.12
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (color ?? Colors.white).withValues(alpha: 0.4), // Increased from 0.2
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (color ?? Colors.black).withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withValues(alpha: 0.4), // Increased from 0.2
                  (color ?? Colors.white).withValues(alpha: 0.1), // Increased from 0.05
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color ?? Colors.white, size: 24), // Increased size and dynamic color
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
