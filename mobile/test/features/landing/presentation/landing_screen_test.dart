import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cv_mobile/features/landing/presentation/landing_screen.dart';
import 'package:cv_mobile/features/landing/presentation/sections/landing_footer.dart';
import 'package:cv_mobile/features/landing/presentation/sections/landing_hero.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

/// Breakpoints imposes par #251 (mobile, tablette, desktop, tres large).
const _breakpoints = <double>[375, 768, 1280, 1920];

Future<void> _pumpLanding(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/landing',
    routes: [
      GoRoute(path: '/landing', builder: (_, __) => const LandingScreen()),
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

void main() {
  group('LandingScreen (#251 F5)', () {
    for (final width in _breakpoints) {
      testWidgets('a ${width.toInt()}px : hero + footer, aucun overflow',
          (tester) async {
        await _pumpLanding(tester, width);

        expect(find.byType(LandingHero), findsOneWidget);
        expect(find.byType(LandingFooter), findsOneWidget);
        expect(find.text('MonCV'), findsWidgets); // logotype hero + footer
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('inscription depuis le hero -> /register', (tester) async {
      await _pumpLanding(tester, 1280);
      final l = AppLocalizations.of(tester.element(find.byType(LandingHero)))!;

      await tester.tap(find.text(l.createCvFree).first);
      await tester.pumpAndSettle();

      expect(find.text('REGISTER'), findsOneWidget);
    });

    testWidgets('ordre de lecture des sections preserve', (tester) async {
      await _pumpLanding(tester, 1280);

      // Le hero precede le footer dans l'ordre vertical.
      final heroY = tester.getTopLeft(find.byType(LandingHero)).dy;
      final footerY = tester.getTopLeft(find.byType(LandingFooter)).dy;
      expect(heroY, lessThan(footerY));
    });
  });
}
