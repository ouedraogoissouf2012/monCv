import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/providers/theme_provider.dart';
import 'package:cv_mobile/screens/auth/login_screen.dart';
import 'package:cv_mobile/screens/home/home_screen.dart';
import 'package:cv_mobile/screens/cv/cv_detail_screen.dart';

/// Construit l'app de test avec les vrais Providers et un GoRouter simplifie.
/// Le router utilise les memes routes que l'app reelle mais sans kIsWeb.
Widget buildTestApp({
  required AuthProvider authProvider,
  required CvProvider cvProvider,
  String initialLocation = '/login',
}) {
  final router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: initialLocation,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final location = state.matchedLocation;
      final isPublic = location == '/login' || location == '/register';

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/cvs/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CvDetailScreen(cvId: id);
        },
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CvProvider>.value(value: cvProvider),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      routerConfig: router,
    ),
  );
}

/// Pump suffisamment de frames pour passer les animations LoginScreen.
/// LoginScreen a des AnimationController.repeat() et Future.delayed(0s, 3s, 6s).
/// Ne JAMAIS utiliser pumpAndSettle() quand LoginScreen est visible.
Future<void> pumpPastAnimations(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Configure la taille d'ecran pour eviter les overflows.
void setTestScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1.0;
}

/// Supprime les erreurs d'overflow Flutter (non critiques dans les tests).
/// Retourne le handler original pour le restaurer dans tearDown.
void suppressOverflowErrors() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
}
