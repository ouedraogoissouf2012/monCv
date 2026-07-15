// mobile/lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'app_colors.dart';

class AppThemes {
  static ColorScheme colorScheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.vibrant:
        return _vibrantColors;
      case AppThemeMode.premium:
        return _premiumColors;
      case AppThemeMode.minimal:
        return _minimalColors;
    }
  }

  static ThemeData get(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.vibrant:
        return _vibrant;
      case AppThemeMode.premium:
        return _premium;
      case AppThemeMode.minimal:
        return _minimal;
    }
  }

  // ── MINIMAL ──────────────────────────────────────────────
  static const ColorScheme _minimalColors = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.blueSurface,
    onPrimaryContainer: AppColors.neutral900,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.neutral75,
    onSecondaryContainer: AppColors.neutral900,
    surface: AppColors.coolSurface,
    onSurface: AppColors.neutral800,
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.neutral500,
  );

  static final ThemeData _minimal = ThemeData(
    useMaterial3: true,
    colorScheme: _minimalColors,
    scaffoldBackgroundColor: AppColors.coolBackground,
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.coolSurface,
      foregroundColor: AppColors.neutral800,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral75,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── VIBRANT ──────────────────────────────────────────────
  static const ColorScheme _vibrantColors = ColorScheme.light(
    primary: AppColors.vibrantPrimary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.violetSurface,
    onPrimaryContainer: AppColors.neutral900,
    secondary: AppColors.vibrantSecondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.violetContainer,
    onSecondaryContainer: AppColors.neutral900,
    surface: AppColors.white,
    onSurface: AppColors.neutral900,
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.neutral500,
  );

  static final ThemeData _vibrant = ThemeData(
    useMaterial3: true,
    colorScheme: _vibrantColors,
    scaffoldBackgroundColor: AppColors.violetSurface,
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.violetSurface,
      foregroundColor: AppColors.neutral900,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vibrantPrimary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.violetContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.vibrantPrimary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── PREMIUM ──────────────────────────────────────────────
  static const ColorScheme _premiumColors = ColorScheme.dark(
    primary: AppColors.premiumPrimary,
    onPrimary: AppColors.neutral950,
    primaryContainer: AppColors.premiumContainer,
    onPrimaryContainer: AppColors.premiumOnSurface,
    secondary: AppColors.premiumSecondary,
    onSecondary: AppColors.neutral950,
    secondaryContainer: AppColors.premiumContainer,
    onSecondaryContainer: AppColors.premiumOnSurface,
    surface: AppColors.premiumSurface,
    onSurface: AppColors.premiumOnSurface,
    error: AppColors.redStrong,
    onError: AppColors.neutral950,
    outline: AppColors.premiumPrimary,
  );

  static final ThemeData _premium = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _premiumColors,
    scaffoldBackgroundColor: AppColors.premiumBackground,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.premiumBackground,
      foregroundColor: AppColors.premiumOnSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.premiumSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.premiumOutlineSoft, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.premiumPrimary,
        foregroundColor: AppColors.premiumBackground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.premiumContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.premiumOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.premiumPrimary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
