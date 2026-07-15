import 'dart:math' as math;

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:cv_mobile/providers/theme_provider.dart';
import 'package:cv_mobile/screens/splash_screen.dart';
import 'package:cv_mobile/utils/app_colors.dart';
import 'package:cv_mobile/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  final ratio = _contrastRatio(background, foreground);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$name contrast was ${ratio.toStringAsFixed(2)}:1',
  );
}

double _contrastRatio(Color first, Color second) {
  final lighter = _luminance(first) > _luminance(second) ? first : second;
  final darker = identical(lighter, first) ? second : first;
  return (_luminance(lighter) + 0.05) / (_luminance(darker) + 0.05);
}

double _luminance(Color color) {
  final argb = color.toARGB32();
  final red = (argb >> 16) & 0xff;
  final green = (argb >> 8) & 0xff;
  final blue = argb & 0xff;

  double channel(int value) {
    final normalized = value / 255;
    return normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(red) +
      0.7152 * channel(green) +
      0.0722 * channel(blue);
}
