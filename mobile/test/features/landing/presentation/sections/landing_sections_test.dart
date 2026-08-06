import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cv_mobile/features/landing/presentation/sections/landing_cta.dart';
import 'package:cv_mobile/features/landing/presentation/sections/landing_footer.dart';
import 'package:cv_mobile/features/landing/presentation/sections/landing_hero.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget section, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: SingleChildScrollView(child: section))),
      GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(body: Text('REGISTER'))),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN'))),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    routerConfig: router,
  ));
  await tester.pumpAndSettle();
}

AppLocalizations _l(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

void main() {
  group('LandingHero (#251 F2)', () {
    testWidgets('desktop : logotype, titre large, CTA inscription/connexion',
        (tester) async {
      await _pump(tester, const LandingHero(), width: 1000);
      final l = _l(tester);

      expect(find.text('MonCV'), findsOneWidget);
      expect(find.text(l.landingHeroTitle), findsOneWidget);
      expect(find.text(l.createCvFree), findsOneWidget);
      expect(find.text(l.login), findsOneWidget);
    });

    testWidgets('mobile : variante de titre mobile', (tester) async {
      await _pump(tester, const LandingHero(), width: 400);
      final l = _l(tester);

      expect(find.text(l.landingHeroTitleMobile), findsOneWidget);
    });

    testWidgets('CTA principal -> /register', (tester) async {
      await _pump(tester, const LandingHero(), width: 1000);
      await tester.tap(find.text(_l(tester).createCvFree));
      await tester.pumpAndSettle();

      expect(find.text('REGISTER'), findsOneWidget);
    });

    testWidgets('CTA secondaire -> /login', (tester) async {
      await _pump(tester, const LandingHero(), width: 1000);
      await tester.tap(find.text(_l(tester).login));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
    });
  });

  group('LandingCta (#251 F2)', () {
    testWidgets('titre, sous-titre et bouton -> /register', (tester) async {
      await _pump(tester, const LandingCta(), width: 1000);
      final l = _l(tester);

      expect(find.text(l.readyToApply), findsOneWidget);
      expect(find.text(l.readyToApplySubtitle), findsOneWidget);

      await tester.tap(find.text(l.startNow));
      await tester.pumpAndSettle();
      expect(find.text('REGISTER'), findsOneWidget);
    });
  });

  group('LandingFooter (#251 F2)', () {
    testWidgets('logotype et mention', (tester) async {
      await _pump(tester, const LandingFooter(), width: 1000);

      expect(find.text('MonCV'), findsOneWidget);
      expect(find.text(_l(tester).landingFooter), findsOneWidget);
    });
  });
}
