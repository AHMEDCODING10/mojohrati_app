import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryGold,
    scaffoldBackgroundColor: AppColors.lightBackground,
    fontFamily: 'Almarai',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGold,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryGold),
      titleTextStyle: GoogleFonts.cairo(
        color: Colors.black87,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Montserrat',
        color: AppColors.lightTextPrimary, 
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Montserrat',
        color: AppColors.lightTextPrimary, 
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.cairo(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.cairo(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: const TextStyle(fontFamily: 'Almarai', color: AppColors.lightTextPrimary),
      bodyMedium: const TextStyle(fontFamily: 'Almarai', color: AppColors.lightTextSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      prefixIconColor: AppColors.primaryGold,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13, fontFamily: 'Almarai'),
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14, fontFamily: 'Almarai'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryGold,
    scaffoldBackgroundColor: AppColors.premiumBlack,
    fontFamily: 'Almarai',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGold,
      secondary: AppColors.accent,
      surface: Color(0xFF121212),
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryGold),
      titleTextStyle: GoogleFonts.cairo(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Montserrat',
        color: AppColors.darkTextPrimary, 
        fontWeight: FontWeight.w900, 
        letterSpacing: -0.5,
        fontSize: 32,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Montserrat',
        color: AppColors.darkTextPrimary, 
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.cairo(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.cairo(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: const TextStyle(fontFamily: 'Almarai', color: AppColors.darkTextPrimary, letterSpacing: 0.2),
      bodyMedium: const TextStyle(fontFamily: 'Almarai', color: AppColors.darkTextSecondary, letterSpacing: 0.1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E), // Slightly elevated from true black
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      prefixIconColor: AppColors.primaryGold,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'Almarai'),
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Almarai'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
  );
}
