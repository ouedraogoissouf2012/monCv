import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
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
import 'screens/privacy/privacy_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/applications/applications_screen.dart';

class AppRouter {
  @visibleForTesting
  static String? resolveAuthRedirect({
    required bool isCheckingAuth,
    required bool isAuthenticated,
    required String location,
    required bool isWeb,
  }) {
    if (isCheckingAuth) return null;

    final isPublic = location == '/login' ||
        location == '/register' ||
        location == '/privacy' ||
        location == '/landing';

    if (!isAuthenticated && !isPublic) {
      return isWeb ? '/landing' : '/login';
    }
    if (isAuthenticated && isPublic) return '/home';
    return null;
  }

  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/home',
      redirect: (context, state) {
        return resolveAuthRedirect(
          isCheckingAuth: authProvider.isCheckingAuth,
          isAuthenticated: authProvider.isAuthenticated,
          location: state.matchedLocation,
          isWeb: kIsWeb,
        );
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
          path: '/privacy',
          builder: (context, state) => const PrivacyScreen(),
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
        GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen()),
        GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Center(child: Text(state.error.toString())),
      ),
    );
  }
}
