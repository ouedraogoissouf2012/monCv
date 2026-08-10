import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/auth/presentation/controllers/auth_submit_outcome.dart';
import 'package:cv_mobile/features/password_reset/presentation/forgot_password_controller.dart';
import 'package:cv_mobile/features/password_reset/presentation/reset_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrôleurs reset (issue #381) : validation LOCALE avant appel, état de
/// chargement, mapping Result -> AuthSubmitOutcome, capture de l'erreur.
void main() {
  group('ForgotPasswordController', () {
    test('email vide -> invalidInput, aucun appel réseau', () async {
      var called = false;
      final c = ForgotPasswordController(submit: (_) async {
        called = true;
        return const Result.success(null);
      });

      expect(await c.submit('   '), AuthSubmitOutcome.invalidInput);
      expect(called, isFalse);
    });

    test('email sans @ -> invalidInput', () async {
      final c = ForgotPasswordController(
          submit: (_) async => const Result.success(null));

      expect(await c.submit('nope'), AuthSubmitOutcome.invalidInput);
    });

    test('succès -> success, email trimé transmis', () async {
      String? seen;
      final c = ForgotPasswordController(submit: (e) async {
        seen = e;
        return const Result.success(null);
      });

      expect(await c.submit('  a@b.c  '), AuthSubmitOutcome.success);
      expect(seen, 'a@b.c');
      expect(c.lastError, isNull);
    });

    test('échec -> backendError + lastError renseigné', () async {
      final c = ForgotPasswordController(
          submit: (_) async => const Result.failure(NetworkException()));

      expect(await c.submit('a@b.c'), AuthSubmitOutcome.backendError);
      expect(c.lastError, isA<NetworkException>());
    });
  });

  group('ResetPasswordController', () {
    test('mot de passe trop court -> invalidInput, aucun appel', () async {
      var called = false;
      final c = ResetPasswordController(submit: (_) async {
        called = true;
        return const Result.success(null);
      });

      expect(
          await c.submit(newPassword: '123'), AuthSubmitOutcome.invalidInput);
      expect(called, isFalse);
    });

    test('succès -> success, transmet le mot de passe', () async {
      String? seen;
      final c = ResetPasswordController(submit: (p) async {
        seen = p;
        return const Result.success(null);
      });

      expect(await c.submit(newPassword: 'NouveauMotDePasse1'),
          AuthSubmitOutcome.success);
      expect(seen, 'NouveauMotDePasse1');
    });

    test('échec (jeton invalide) -> backendError + lastError', () async {
      final c = ResetPasswordController(
          submit: (_) async => const Result.failure(ServerException()));

      expect(await c.submit(newPassword: 'NouveauMotDePasse1'),
          AuthSubmitOutcome.backendError);
      expect(c.lastError, isA<ServerException>());
    });

    test('onPasswordChanged met à jour le score de force', () {
      final c = ResetPasswordController(
          submit: (_) async => const Result.success(null));

      expect(c.passwordScore, 0);
      c.onPasswordChanged('Abcdef1!ghij');
      expect(c.passwordScore, greaterThan(0));
    });
  });
}
