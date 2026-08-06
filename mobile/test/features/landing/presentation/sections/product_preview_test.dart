import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/landing/presentation/landing_sample_cv.dart';
import 'package:cv_mobile/features/landing/presentation/sections/product_preview.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale('fr'),
    home: Scaffold(
      body: SingleChildScrollView(child: ProductPreview()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('ProductPreview (#251 F4)', () {
    testWidgets('en-tete + mock : nom, sections et competences de la fixture',
        (tester) async {
      await _pump(tester);
      final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

      expect(find.text(l.clearCvTitle), findsOneWidget);
      expect(find.text(l.sampleCandidateName), findsOneWidget);
      expect(find.text(l.sampleSkills), findsOneWidget);

      // Chaque competence de la fixture est rendue en puce.
      for (final skill in LandingSampleCv.skills) {
        expect(find.text(skill), findsOneWidget);
      }
      expect(find.text(LandingSampleCv.experiencePeriod), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile : sans overflow', (tester) async {
      await _pump(tester, width: 375);
      expect(tester.takeException(), isNull);
    });
  });
}
