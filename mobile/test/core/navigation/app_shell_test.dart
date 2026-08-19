import 'package:cv_mobile/core/navigation/app_destination.dart';
import 'package:cv_mobile/core/navigation/app_shell.dart';
import 'package:cv_mobile/core/navigation/responsive_navigation.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('appDestinations (#249 D2)', () {
    test('5 destinations avec routes attendues', () {
      expect(appDestinations, hasLength(5));
      expect(appDestinations.map((d) => d.route), [
        '/home',
        '/cvs/create',
        '/applications',
        '/profile',
        '/cvs/trash',
      ]);
      expect(appDestinations.last.sidebarOnly, isTrue);
    });

    test('creation est empilee (push), les autres remplacent (go)', () {
      expect(appDestinations[1].push, isTrue, reason: '/cvs/create empile');
      expect(appDestinations[0].push, isFalse);
      expect(appDestinations[2].push, isFalse);
    });
  });

  // Router minimal qui enregistre la derniere route visitee.
  final visited = <String>[];
  GoRouter router(Widget home) => GoRouter(
        initialLocation: '/home',
        routes: [
          for (final path in ['/home', '/applications', '/profile', '/cvs/trash'])
            GoRoute(
                path: path,
                builder: (_, __) {
                  visited.add(path);
                  return home;
                }),
          GoRoute(
              path: '/cvs/create',
              builder: (_, __) {
                visited.add('/cvs/create');
                return const Scaffold(body: Text('create'));
              }),
        ],
      );

  Widget app(Widget home) => MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router(home),
      );

  /// Fixe la vraie taille de surface (largeur -> mobile/desktop).
  Future<void> pumpAt(WidgetTester t, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(app(const AppShell(body: Text('corps'), currentIndex: 0)));
    await t.pumpAndSettle();
  }

  setUp(visited.clear);

  testWidgets('mobile : affiche la NavigationBar (pas la sidebar)', (t) async {
    await pumpAt(t, const Size(500, 900));
    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(find.byType(AppSidebar), findsNothing);
    expect(find.text('corps'), findsOneWidget);
  });

  testWidgets('desktop : affiche la sidebar (pas la NavigationBar)', (t) async {
    await pumpAt(t, const Size(1300, 900));
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(AppBottomNavigation), findsNothing);
  });

  testWidgets('tap sur "Candidatures" navigue vers /applications', (t) async {
    await pumpAt(t, const Size(500, 900));
    final l = AppLocalizations.of(t.element(find.text('corps')))!;

    await t.tap(find.text(l.applications).last);
    await t.pumpAndSettle();

    expect(visited.last, '/applications');
  });
}
