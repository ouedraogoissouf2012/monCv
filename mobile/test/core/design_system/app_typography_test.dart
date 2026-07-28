import 'dart:io';

import 'package:cv_mobile/core/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garantit que la typographie est resolue de facon deterministe via les
/// polices embarquees, et qu'aucun ecran ne rappelle `GoogleFonts` au runtime
/// (issue #233).
void main() {
  group('AppTypography.textTheme', () {
    // Base Material standard : les tailles ne doivent pas changer, seule la
    // famille est appliquee (parite avec l'ancien GoogleFonts.poppinsTextTheme).
    final base = Typography.material2021().black;
    final theme = AppTypography.textTheme(base);

    test('applies the embedded body family to every role', () {
      final roles = <String, TextStyle?>{
        'displayLarge': theme.displayLarge,
        'headlineSmall': theme.headlineSmall,
        'titleMedium': theme.titleMedium,
        'bodyMedium': theme.bodyMedium,
        'labelSmall': theme.labelSmall,
      };
      roles.forEach((name, style) {
        expect(style?.fontFamily, AppTypography.fontFamilyBody, reason: name);
      });
    });

    test('preserves the base Material sizes (no typographic redesign)', () {
      // La geometrie doit rester celle de la base : seule la police change.
      expect(theme.displayLarge?.fontSize, base.displayLarge?.fontSize);
      expect(theme.titleLarge?.fontSize, base.titleLarge?.fontSize);
      expect(theme.bodyMedium?.fontSize, base.bodyMedium?.fontSize);
      expect(theme.labelSmall?.fontSize, base.labelSmall?.fontSize);
    });
  });

  group('AppTypography.display', () {
    test('uses the embedded display family and propagates every field', () {
      const color = Color(0xFF123456);
      final style = AppTypography.display(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
        letterSpacing: -0.5,
      );

      expect(style.fontFamily, AppTypography.fontFamilyDisplay);
      expect(style.fontSize, 32);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, color);
      expect(style.height, 1.2);
      expect(style.letterSpacing, -0.5);
    });

    test('defaults to a regular weight when unspecified', () {
      final style = AppTypography.display(fontSize: 20);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, isNull);
    });
  });

  // Invariant de l'issue : aucun ecran de l'app ne resout une police via un
  // appel reseau runtime. Le rendu du document CV (widgets/cv_preview.dart,
  // pdf/) garde volontairement son propre catalogue et est hors perimetre.
  test('no screen imports or calls GoogleFonts at runtime', () {
    final screensDir = Directory('lib/screens');
    expect(screensDir.existsSync(), isTrue,
        reason: 'lib/screens introuvable depuis ${Directory.current.path}');

    final offenders = <String>[];
    for (final entity in screensDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (entity.readAsStringSync().contains('GoogleFonts')) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'GoogleFonts doit rester hors des ecrans: $offenders');
  });
}
