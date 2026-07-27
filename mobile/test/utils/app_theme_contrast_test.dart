import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:cv_mobile/providers/theme_provider.dart';
import 'package:cv_mobile/screens/splash_screen.dart';
import 'package:cv_mobile/utils/app_colors.dart';
import 'package:cv_mobile/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/wcag_contrast.dart';

void main() {
  group('AppThemes contrast', () {
    for (final mode in AppThemeMode.values) {
      test('$mode exposes WCAG AA semantic color pairs', () {
        final colors = AppThemes.colorScheme(mode);

        _expectContrast('primary', colors.primary, colors.onPrimary);
        _expectContrast('secondary', colors.secondary, colors.onSecondary);
        _expectContrast('surface', colors.surface, colors.onSurface);
        _expectContrast('error', colors.error, colors.onError);
      });
    }

    test('business status tokens expose WCAG AA foregrounds', () {
      _expectContrast('success', AppColors.success, AppColors.onSuccess);
      _expectContrast('warning', AppColors.warning, AppColors.onWarning);
      _expectContrast('info', AppColors.info, AppColors.onInfo);
      _expectContrast('error', AppColors.error, AppColors.onError);

      _expectContrast('draft', AppColors.white, AppColors.statusDraft);
      _expectContrast('sent', AppColors.white, AppColors.statusSent);
      _expectContrast(
        'interview',
        AppColors.white,
        AppColors.statusInterview,
      );
      _expectContrast(
        'technical test',
        AppColors.white,
        AppColors.statusTechnicalTest,
      );
      _expectContrast('offer', AppColors.white, AppColors.statusOffer);
      _expectContrast('rejected', AppColors.white, AppColors.statusRejected);
      _expectContrast('archived', AppColors.white, AppColors.statusArchived);
    });

    test('feedback containers expose WCAG AA foregrounds', () {
      _expectContrast('error surface', AppColors.redSurface, AppColors.error);
      _expectContrast(
        'warning surface',
        AppColors.orangeSurface,
        AppColors.warning,
      );
      _expectContrast(
        'success surface',
        AppColors.greenSurface,
        AppColors.success,
      );
      _expectContrast('info surface', AppColors.blueSurface, AppColors.info);
    });
  });

  testWidgets('Splash pilot passes Flutter contrast guidelines',
      (tester) async {
    await tester.pumpWidget(
      AccessibilityTools(
        checkSemanticLabels: false,
        minimumTapAreas: null,
        testingToolsConfiguration: const TestingToolsConfiguration(
          enabled: false,
        ),
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: AppThemes.colorScheme(AppThemeMode.minimal),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

void _expectContrast(String name, Color background, Color foreground) {
  final ratio = contrastRatio(background, foreground);
  expect(
    ratio,
    greaterThanOrEqualTo(kWcagAaNormalText),
    reason: '$name contrast was ${ratio.toStringAsFixed(2)}:1',
  );
}
