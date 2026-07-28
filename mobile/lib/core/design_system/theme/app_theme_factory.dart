import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_theme_spec.dart';

/// Fabrique unique de [ThemeData] pour l'application.
///
/// La definition des themes de composants est ecrite **une seule fois** ici et
/// parametree par un [AppThemeSpec] : Minimal, Vibrant et Premium ne dupliquent
/// aucun theme de composant (issue #233), ils ne fournissent que leurs
/// differences via le spec.
///
/// **Non-regression** : cette fabrique reproduit a l'identique les themes de
/// composants qui preexistaient dans `AppThemes` (appBar, card, boutons
/// eleves, champs) et la typographie (echelle Material + Poppins). Elle
/// n'ajoute aucun theme de composant nouveau : tout elargissement (sheets,
/// dialogs, navigation, snackbars) devra venir avec ses goldens, dans une PR
/// dediee, pour ne pas introduire de redesign implicite.
abstract final class AppThemeFactory {
  const AppThemeFactory._();

  /// Elevation nulle : le design system s'appuie sur les surfaces et les
  /// bordures, pas sur les ombres Material par defaut (comportement d'origine).
  static const double _flatElevation = 0;

  /// Epaisseur du lisere de focus des champs (comportement d'origine).
  static const double _focusBorderWidth = 2;

  /// Construit le [ThemeData] complet a partir d'un [AppThemeSpec].
  static ThemeData build(AppThemeSpec spec) {
    final scheme = spec.colorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: spec.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: spec.scaffoldBackground,
      textTheme: _textTheme(spec.brightness),
      extensions: <ThemeExtension<dynamic>>[spec.colorTokens],
      appBarTheme: _appBarTheme(spec),
      cardTheme: _cardTheme(spec),
      elevatedButtonTheme: _elevatedButtonTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(spec),
    );
  }

  /// Applique la police embarquee au [TextTheme] Material du mode, sans changer
  /// l'echelle. Base claire ou sombre selon la luminosite, a l'identique de
  /// l'ancien `GoogleFonts.poppinsTextTheme([ThemeData.dark().textTheme])`.
  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return AppTypography.textTheme(base);
  }

  static AppBarTheme _appBarTheme(AppThemeSpec spec) => AppBarTheme(
        backgroundColor: spec.appBarBackground,
        foregroundColor: spec.appBarForeground,
        // Neutralise la teinte M3 uniquement la ou le theme d'origine le
        // faisait (Vibrant); sinon on garde le defaut Material.
        surfaceTintColor: spec.flattenAppBarTint ? Colors.transparent : null,
        elevation: _flatElevation,
        centerTitle: false,
      );

  static CardThemeData _cardTheme(AppThemeSpec spec) => CardThemeData(
        color: spec.cardColor,
        elevation: _flatElevation,
        shadowColor: spec.cardShadowColor,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md + AppSpacing.xxs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
          elevation: _flatElevation,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + AppSpacing.xxs,
      ),
    );
  }
}
