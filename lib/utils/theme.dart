import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system matching the original Life Companion aesthetic:
/// Editorial/minimalist, mobile-first.
class AppColors {
  static const background = Color(0xFFF5F5F0);
  static const accent = Color(0xFF5A5A40);
  static const mutedText = Color(0xFF9E9E9E);
  static const cardBorder = Color(0xFFE5E5E5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textBody = Color(0xFF333333);
  static const error = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get theme {
    final serifFont = GoogleFonts.loraTextTheme();
    final sansFont = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: serifFont.copyWith(
        // Labels: uppercase tracking
        labelSmall: sansFont.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: AppColors.accent,
        ),
        labelMedium: sansFont.labelMedium?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: AppColors.mutedText,
        ),
        // Headlines
        headlineLarge: serifFont.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        ),
        headlineMedium: serifFont.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        ),
        // Body
        bodyLarge: serifFont.bodyLarge?.copyWith(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          color: AppColors.textBody,
          height: 1.6,
        ),
        bodyMedium: serifFont.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textBody,
        ),
        bodySmall: serifFont.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.mutedText,
        ),
        // Display (large numbers)
        displayMedium: serifFont.displayMedium?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: sansFont.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
