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

      test('$mode wires component themes from the shared factory', () {
        // Aucune definition dupliquee par mode : la factory garantit que tous
        // les themes de composants sont peuples avec les rayons du token set.
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.bottomSheetTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());

        final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(cardShape.borderRadius, AppRadii.xl);
      });

      test('$mode brightness matches its spec', () {
        expect(theme.brightness, spec.brightness);
        expect(theme.colorScheme.brightness, spec.brightness);
      });
    }

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
