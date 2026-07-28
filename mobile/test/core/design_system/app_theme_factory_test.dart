import 'package:cv_mobile/core/design_system/theme/app_theme_factory.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_mode.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_modes.dart';
import 'package:cv_mobile/core/design_system/tokens/app_color_tokens.dart';
import 'package:cv_mobile/core/design_system/tokens/app_radii.dart';
import 'package:cv_mobile/core/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifie que la fabrique commune produit un [ThemeData] coherent pour chaque
/// mode, sans dupliquer les themes de composants, et sans redesign implicite
/// (les [ColorScheme] restent ceux d'origine).
void main() {
  group('AppThemeFactory', () {
    for (final mode in AppThemeMode.values) {
      final spec = AppThemeModes.of(mode);
      final theme = AppThemeFactory.build(spec);

      test('$mode uses Material 3 and the embedded body font', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyMedium?.fontFamily,
            AppTypography.fontFamilyBody);
      });

      test('$mode exposes the semantic color tokens extension', () {
        final tokens = theme.extension<AppColorTokens>();
        expect(tokens, isNotNull);
        expect(tokens, same(spec.colorTokens));
      });

      test('$mode reproduces the original component themes exactly', () {
        // Non-regression : mêmes valeurs que l'ancien AppThemes, produites par
        // les tokens. La factory n'ajoute AUCUN theme de composant nouveau
        // (pas de redesign implicite) — seuls appBar/card/bouton/champ existent.
        final card = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(card.borderRadius, AppRadii.xl); // circular(16) d'origine
        expect(theme.cardTheme.elevation, 0);

        expect(theme.inputDecorationTheme.filled, isTrue);
        final inputBorder =
            theme.inputDecorationTheme.border as OutlineInputBorder;
        expect(inputBorder.borderRadius, AppRadii.lg); // circular(12) d'origine
        expect(theme.inputDecorationTheme.contentPadding,
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14));

        final buttonStyle = theme.elevatedButtonTheme.style!;
        expect(buttonStyle.padding!.resolve({}),
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14));
        final buttonShape =
            buttonStyle.shape!.resolve({}) as RoundedRectangleBorder;
        expect(buttonShape.borderRadius, AppRadii.lg); // circular(12) d'origine
      });

      test('$mode does not introduce new component themes (no redesign)', () {
        // Ces themes n'existaient pas dans l'ancien AppThemes : la factory ne
        // doit pas les surcharger tant que leurs goldens n'ont pas ete figes.
        final defaults = ThemeData(brightness: spec.brightness);
        expect(theme.snackBarTheme, defaults.snackBarTheme);
        expect(theme.navigationBarTheme, defaults.navigationBarTheme);
        expect(theme.bottomSheetTheme, defaults.bottomSheetTheme);
        expect(theme.dialogTheme, defaults.dialogTheme);
        expect(theme.textButtonTheme, defaults.textButtonTheme);
        expect(theme.outlinedButtonTheme, defaults.outlinedButtonTheme);
      });

      test('$mode brightness matches its spec', () {
        expect(theme.brightness, spec.brightness);
        expect(theme.colorScheme.brightness, spec.brightness);
      });
    }

    test('card shadow color matches the original per mode', () {
      // Seul Minimal fixait shadowColor: black12 dans l'ancien theme.
      expect(AppThemeFactory.build(AppThemeModes.minimal).cardTheme.shadowColor,
          const Color(0x1F000000)); // Colors.black12
      expect(AppThemeFactory.build(AppThemeModes.vibrant).cardTheme.shadowColor,
          isNull);
      expect(AppThemeFactory.build(AppThemeModes.premium).cardTheme.shadowColor,
          isNull);
    });

    test('appbar surface tint matches the original per mode', () {
      // Seul Vibrant neutralisait la teinte M3 dans l'ancien theme.
      expect(AppThemeFactory.build(AppThemeModes.vibrant).appBarTheme
          .surfaceTintColor, const Color(0x00000000)); // transparent
      expect(AppThemeFactory.build(AppThemeModes.minimal).appBarTheme
          .surfaceTintColor, isNull);
      expect(AppThemeFactory.build(AppThemeModes.premium).appBarTheme
          .surfaceTintColor, isNull);
    });

    test('color schemes are preserved per mode (no implicit redesign)', () {
      expect(AppThemeModes.minimal.colorScheme.primary,
          const Color(0xFF2563EB)); // AppColors.primary
      expect(AppThemeModes.vibrant.colorScheme.primary,
          const Color(0xFF5B4BD8)); // AppColors.vibrantPrimary
      expect(AppThemeModes.premium.colorScheme.primary,
          const Color(0xFFFFD700)); // AppColors.premiumPrimary
    });

    test('input fill differs per mode but shape is shared', () {
      final minimal = AppThemeFactory.build(AppThemeModes.minimal);
      final premium = AppThemeFactory.build(AppThemeModes.premium);
      expect(minimal.inputDecorationTheme.fillColor,
          isNot(premium.inputDecorationTheme.fillColor));
      expect(minimal.inputDecorationTheme.border,
          premium.inputDecorationTheme.border);
    });
  });
}
