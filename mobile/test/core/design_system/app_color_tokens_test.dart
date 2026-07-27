import 'package:cv_mobile/core/design_system/theme/app_theme_mode.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_modes.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_spec.dart';
import 'package:cv_mobile/core/design_system/tokens/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/wcag_contrast.dart';

/// Verifie que chaque paire semantique (`couleur` / `onCouleur`) et chaque
/// indicateur de score de chaque mode atteint le contraste WCAG AA (issue
/// #233 : "tests de contraste WCAG AA pour chaque paire semantique et chaque
/// mode").
void main() {
  // Chaque mode reel : associe une palette de tokens a ses surfaces effectives.
  final specsByMode = <AppThemeMode, AppThemeSpec>{
    for (final mode in AppThemeMode.values) mode: AppThemeModes.of(mode),
  };

  group('AppColorTokens WCAG AA contrast', () {
    specsByMode.forEach((mode, spec) {
      final tokens = spec.colorTokens;

      test('$mode status/feedback pairs meet AA normal text', () {
        _expectAa(mode, 'success', tokens.success, tokens.onSuccess);
        _expectAa(mode, 'warning', tokens.warning, tokens.onWarning);
        _expectAa(mode, 'info', tokens.info, tokens.onInfo);
        _expectAa(mode, 'danger', tokens.danger, tokens.onDanger);
        _expectAa(mode, 'offline', tokens.offline, tokens.onOffline);
      });

      test('$mode application-status chips meet AA against onStatus', () {
        final chips = <String, Color>{
          'draft': tokens.statusDraft,
          'sent': tokens.statusSent,
          'interview': tokens.statusInterview,
          'technicalTest': tokens.statusTechnicalTest,
          'offer': tokens.statusOffer,
          'rejected': tokens.statusRejected,
          'archived': tokens.statusArchived,
        };
        chips.forEach((label, color) {
          _expectAa(mode, 'status:$label', color, tokens.onStatus);
        });
      });

      // Les couleurs de score servent de texte/barre pose sur les surfaces du
      // mode : elles doivent contraster avec scaffoldBackground ET cardColor.
      test('$mode score indicators meet AA against real surfaces', () {
        final scores = <String, Color>{
          'scoreGood': tokens.scoreGood,
          'scoreMedium': tokens.scoreMedium,
          'scorePoor': tokens.scorePoor,
        };
        final surfaces = <String, Color>{
          'scaffold': spec.scaffoldBackground,
          'card': spec.cardColor,
        };
        scores.forEach((sLabel, sColor) {
          surfaces.forEach((surfLabel, surfColor) {
            _expectAa(mode, '$sLabel/$surfLabel', sColor, surfColor);
          });
        });
      });
    });

    test('lerp respects endpoint and midpoint invariants', () {
      const a = AppColorTokens.light;
      const b = AppColorTokens.dark;
      // Invariants de ThemeExtension.lerp aux bornes.
      expect(a.lerp(b, 0).success, a.success);
      expect(a.lerp(b, 1).success, b.success);
      // Le point median doit etre l'interpolation exacte, pas une teinte tierce.
      expect(a.lerp(b, 0.5).success, Color.lerp(a.success, b.success, 0.5));
    });

    test('lerp with a non-matching extension returns this', () {
      const a = AppColorTokens.light;
      expect(a.lerp(null, 0.5), same(a));
    });

    test('copyWith overrides only the requested channel', () {
      const replacement = Color(0xFF123456);
      final patched = AppColorTokens.light.copyWith(success: replacement);
      expect(patched.success, replacement);
      expect(patched.warning, AppColorTokens.light.warning);
      expect(patched.onStatus, AppColorTokens.light.onStatus);
    });
  });
}

void _expectAa(AppThemeMode mode, String pair, Color bg, Color fg) {
  final ratio = contrastRatio(bg, fg);
  expect(
    ratio,
    greaterThanOrEqualTo(kWcagAaNormalText),
    reason: '[$mode] $pair contrast is ${ratio.toStringAsFixed(2)}:1 '
        '(need >= $kWcagAaNormalText:1)',
  );
}
