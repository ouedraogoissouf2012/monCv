import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/cv.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/cv/cv_detail_screen.dart';
import 'screens/cv/cv_form_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/landing/landing_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/home',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final location = state.matchedLocation;
        final isPublic = location == '/login' ||
            location == '/register' ||
            location == '/landing';

        if (!isLoggedIn && !isPublic) {
          return kIsWeb ? '/landing' : '/login';
        }
        if (isLoggedIn && isPublic) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/landing',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/cvs/create',
          builder: (context, state) => const CvFormScreen(),
        ),
        GoRoute(
          path: '/cvs/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CvDetailScreen(cvId: id);
          },
        ),
        GoRoute(
          path: '/cvs/:id/edit',
          builder: (context, state) {
            final cv = state.extra as Cv;
            return CvFormScreen(cv: cv);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Center(child: Text(state.error.toString())),
      ),
    );
  }
}
