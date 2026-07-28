import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../tokens/app_color_tokens.dart';
import 'app_theme_mode.dart';
import 'app_theme_spec.dart';

/// Specs des trois themes de l'application. Chaque mode ne declare que ses
/// **differences** (couleurs, fonds, remplissages, bordures); la construction
/// du [ThemeData] est mutualisee dans `AppThemeFactory`.
///
/// Les [ColorScheme] reprennent a l'identique ceux qui preexistaient dans
/// `AppThemes` : ce refactor centralise la structure sans redesign implicite
/// (contrainte de non-regression de l'issue #233).
abstract final class AppThemeModes {
  const AppThemeModes._();

  /// Retourne le spec correspondant au mode demande.
  static AppThemeSpec of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.minimal:
        return minimal;
      case AppThemeMode.vibrant:
        return vibrant;
      case AppThemeMode.premium:
        return premium;
    }
  }

  static const AppThemeSpec minimal = AppThemeSpec(
    colorScheme: _minimalColors,
    brightness: Brightness.light,
    scaffoldBackground: AppColors.coolBackground,
    appBarBackground: AppColors.coolSurface,
    appBarForeground: AppColors.neutral800,
    cardColor: AppColors.white,
    // Ombre douce reprise a l'identique de l'ancien theme Minimal.
    cardShadowColor: Colors.black12,
    inputFill: AppColors.neutral75,
    colorTokens: AppColorTokens.light,
  );

  static const AppThemeSpec vibrant = AppThemeSpec(
    colorScheme: _vibrantColors,
    brightness: Brightness.light,
    scaffoldBackground: AppColors.violetSurface,
    appBarBackground: AppColors.violetSurface,
    appBarForeground: AppColors.neutral900,
    cardColor: AppColors.white,
    inputFill: AppColors.violetContainer,
    colorTokens: AppColorTokens.light,
    flattenAppBarTint: true,
  );

  static const AppThemeSpec premium = AppThemeSpec(
    colorScheme: _premiumColors,
    brightness: Brightness.dark,
    scaffoldBackground: AppColors.premiumBackground,
    appBarBackground: AppColors.premiumBackground,
    appBarForeground: AppColors.premiumOnSurface,
    cardColor: AppColors.premiumSurface,
    inputFill: AppColors.premiumContainer,
    colorTokens: AppColorTokens.dark,
    cardBorderColor: AppColors.premiumOutlineSoft,
    inputEnabledBorderColor: AppColors.premiumOutline,
  );

  // ── ColorSchemes (repris a l'identique de l'ancien AppThemes) ────────────

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
}
