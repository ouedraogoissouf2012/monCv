import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_theme_spec.dart';

/// Fabrique unique de [ThemeData] pour l'application.
///
/// Toute la definition des themes de composants (boutons, champs, cartes,
/// feuilles, dialogues, navigation) est ecrite **une seule fois** ici et
/// parametree par un [AppThemeSpec]. Minimal, Vibrant et Premium ne dupliquent
/// donc aucun theme de composant (issue #233) : ils ne fournissent que leurs
/// differences via le spec.
abstract final class AppThemeFactory {
  const AppThemeFactory._();

  /// Elevation nulle : le design system s'appuie sur les surfaces et les
  /// bordures, pas sur les ombres Material par defaut.
  static const double _flatElevation = 0;

  /// Epaisseur du lisere de focus des champs et contours accentues.
  static const double _focusBorderWidth = 2;

  /// Construit le [ThemeData] complet a partir d'un [AppThemeSpec].
  static ThemeData build(AppThemeSpec spec) {
    final scheme = spec.colorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: spec.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: spec.scaffoldBackground,
      fontFamily: AppTypography.fontFamilyBody,
      textTheme: AppTypography.textTheme().apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[spec.colorTokens],
      appBarTheme: _appBarTheme(spec),
      cardTheme: _cardTheme(spec),
      elevatedButtonTheme: _elevatedButtonTheme(scheme),
      textButtonTheme: _textButtonTheme(scheme),
      outlinedButtonTheme: _outlinedButtonTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(spec),
      bottomSheetTheme: _bottomSheetTheme(spec),
      dialogTheme: _dialogTheme(spec),
      navigationBarTheme: _navigationBarTheme(spec),
      snackBarTheme: _snackBarTheme(spec),
    );
  }

  static AppBarTheme _appBarTheme(AppThemeSpec spec) => AppBarTheme(
        backgroundColor: spec.appBarBackground,
        foregroundColor: spec.appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: _flatElevation,
        centerTitle: false,
      );

  static CardThemeData _cardTheme(AppThemeSpec spec) => CardThemeData(
        color: spec.cardColor,
        elevation: _flatElevation,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.xl,
          side: spec.cardBorderColor == null
              ? BorderSide.none
              : BorderSide(color: spec.cardBorderColor!),
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme scheme) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md + AppSpacing.xxs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
          elevation: _flatElevation,
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme scheme) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xxs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme scheme) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md + AppSpacing.xxs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(AppThemeSpec spec) {
    final scheme = spec.colorScheme;
    final enabledBorder = spec.inputEnabledBorderColor == null
        ? const OutlineInputBorder(
            borderRadius: AppRadii.lg,
            borderSide: BorderSide.none,
          )
        : OutlineInputBorder(
            borderRadius: AppRadii.lg,
            borderSide: BorderSide(color: spec.inputEnabledBorderColor!),
          );

    return InputDecorationTheme(
      filled: true,
      fillColor: spec.inputFill,
      border: const OutlineInputBorder(
        borderRadius: AppRadii.lg,
        borderSide: BorderSide.none,
      ),
      enabledBorder: enabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.lg,
        borderSide: BorderSide(color: scheme.primary, width: _focusBorderWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.lg,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadii.lg,
        borderSide: BorderSide(color: scheme.error, width: _focusBorderWidth),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + AppSpacing.xxs,
      ),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(AppThemeSpec spec) =>
      BottomSheetThemeData(
        backgroundColor: spec.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: _flatElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxlValue),
          ),
        ),
      );

  static DialogThemeData _dialogTheme(AppThemeSpec spec) => DialogThemeData(
        backgroundColor: spec.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: _flatElevation,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xl),
      );

  static NavigationBarThemeData _navigationBarTheme(AppThemeSpec spec) {
    final scheme = spec.colorScheme;
    return NavigationBarThemeData(
      backgroundColor: spec.appBarBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: _flatElevation,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    );
  }

  static SnackBarThemeData _snackBarTheme(AppThemeSpec spec) => SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: spec.colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: spec.colorScheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
      );
}
