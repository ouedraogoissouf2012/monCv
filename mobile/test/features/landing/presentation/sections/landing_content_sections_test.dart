import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/landing/presentation/sections/feature_overview.dart';
import 'package:cv_mobile/features/landing/presentation/sections/social_proof.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget section, {double width = 1200}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: SingleChildScrollView(child: section)),
  ));
  await tester.pumpAndSettle();
}

AppLocalizations _l(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

void main() {
  group('SocialProof (#251 F3)', () {
    testWidgets('affiche les 4 statistiques cles', (tester) async {
      await _pump(tester, const SocialProof());
      final l = _l(tester);

      expect(find.text('FR/EN'), findsOneWidget);
      expect(find.text('ATS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text(l.bilingual), findsOneWidget);
      expect(find.text(l.compatible), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FeatureOverview (#251 F3)', () {
    testWidgets('en-tete + 6 cartes de fonctionnalites', (tester) async {
      await _pump(tester, const FeatureOverview());
      final l = _l(tester);

      expect(find.text(l.allYouNeed), findsOneWidget);
      expect(find.text(l.allYouNeedSubtitle), findsOneWidget);
      for (final title in [
        l.aiFeatureTitle,
        l.templatesFeatureTitle,
        l.atsFeatureTitle,
        l.docxFeatureTitle,
        l.mobileFeatureTitle,
        l.whatsAppFeatureTitle,
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile : cartes empilees sans overflow', (tester) async {
      await _pump(tester, const FeatureOverview(), width: 375);
      expect(tester.takeException(), isNull);
    });
  });
}
