import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  static const Color accent = Color(0xFFFF6584);
  static const Color accentLight = Color(0xFFFF8FA3);

  static const Color gold = Color(0xFFFFD54F);
  static const Color goldDark = Color(0xFFFFA000);

  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceLight = Color(0xFF2A2A3C);
  static const Color surfaceDark = Color(0xFF141420);

  static const Color card = Color(0xFF252538);
  static const Color cardLight = Color(0xFF2E2E44);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6E6E8A);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  static const Color team1 = Color(0xFF64B5F6);
  static const Color team1Dark = Color(0xFF1565C0);
  static const Color team2 = Color(0xFFCE93D8);
  static const Color team2Dark = Color(0xFF6A1B9A);

  static const Color greenFelt = Color(0xFF1A5C2A);
  static const Color greenFeltLight = Color(0xFF228B22);
  static const Color greenFeltDark = Color(0xFF0D3318);

  static const Color wood = Color(0xFF5D4037);
  static const Color woodLight = Color(0xFF6D4C41);
  static const Color woodDark = Color(0xFF3E2723);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration entrance = Duration(milliseconds: 700);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.easeOutBack;
}
