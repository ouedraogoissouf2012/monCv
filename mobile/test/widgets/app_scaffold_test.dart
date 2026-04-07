import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cv_mobile/widgets/app_scaffold.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Root')),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AppScaffold(
          currentIndex: 0,
          body: Text('Home'),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AppScaffold(
          currentIndex: 2,
          body: Text('Profile'),
        ),
      ),
      GoRoute(
        path: '/cvs/create',
        builder: (context, state) => const Scaffold(body: Text('Create CV')),
      ),
    ],
  );
}

void main() {
  group('AppScaffold', () {
    testWidgets('affiche NavigationBar sur mobile (largeur 400)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = _buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(useMaterial3: true),
          routerConfig: router,
        ),
      );
      await tester.pump();

      // Navigate to /home to show AppScaffold
      router.go('/home');
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
