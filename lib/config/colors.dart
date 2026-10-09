import 'package:flutter/material.dart';

class AppColors {
  // Primary Gold Palette
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF1E5AC);
  static const Color darkGold = Color(0xFF996515);
  
  // Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F8F8);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  
  // Dark Theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  // Common Colors
  static const Color accent = Color(0xFFFFD700);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);

  // Glassmorphism effect colors (low opacity)
  static Color glassWhite = Colors.white.withValues(alpha: 0.15);
  static Color glassBlack = Colors.black.withValues(alpha: 0.15);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);

  // Yemen Flag Inspired Accents (Subtle)
  static const Color yemenRed = Color(0xFFCE1126);
  
  // 2026 Next-Gen Liquid Gradients
  static const LinearGradient liquidGold = LinearGradient(
    colors: [
      Color(0xFFD4AF37), // Classic Gold
      Color(0xFFFFDF00), // Bright Gold
      Color(0xFFB8860B), // Dark Goldenrod
      Color(0xFFFFD700), // Pure Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const Color premiumBeige = Color(0xFFEDE6D6);

  static const LinearGradient meshDark = LinearGradient(
    colors: [
      premiumBlack,
      premiumBlack,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshLight = LinearGradient(
    colors: [
      lightBackground,
      lightBackground,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Depth & Glow
  static Color getGlowColor(Color base) => base.withValues(alpha: 0.3);
  static const Color premiumBlack = Color(0xFF080808);
  static const Color royalBlack = Color(0xFF1A1A1A);
  static const Color royalCream = Color(0xFFF5F5DC);
  static const Color matteBlack = Color(0xFF121212);
}
