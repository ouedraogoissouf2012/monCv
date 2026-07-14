import 'package:cv_mobile/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter.resolveAuthRedirect', () {
    test('conserve une route protegee pendant la restauration de session', () {
      final redirect = AppRouter.resolveAuthRedirect(
        isCheckingAuth: true,
        isAuthenticated: false,
        location: '/cvs/:id',
        isWeb: true,
      );

      expect(redirect, null);
    });

    test(
        'redirige une route protegee quand la restauration est terminee sans session',
        () {
      final redirect = AppRouter.resolveAuthRedirect(
        isCheckingAuth: false,
        isAuthenticated: false,
        location: '/cvs/:id',
        isWeb: true,
      );

      expect(redirect, '/landing');
    });

    test('renvoie un utilisateur connecte hors des pages publiques', () {
      final redirect = AppRouter.resolveAuthRedirect(
        isCheckingAuth: false,
        isAuthenticated: true,
        location: '/landing',
        isWeb: true,
      );

      expect(redirect, '/home');
    });

    test('laisse le portfolio public accessible sans session', () {
      final redirect = AppRouter.resolveAuthRedirect(
        isCheckingAuth: false,
        isAuthenticated: false,
        location: '/public/cv/abc123',
        isWeb: true,
      );

      expect(redirect, null);
    });

    test('laisse le portfolio public accessible avec une session', () {
      final redirect = AppRouter.resolveAuthRedirect(
        isCheckingAuth: false,
        isAuthenticated: true,
        location: '/public/cv/abc123',
        isWeb: true,
      );

      expect(redirect, null);
    });
  });
}
