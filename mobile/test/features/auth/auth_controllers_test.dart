import 'package:cv_mobile/features/auth/domain/password_policy.dart';
import 'package:cv_mobile/features/auth/presentation/controllers/auth_submit_outcome.dart';
import 'package:cv_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:cv_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginController (#248 C3)', () {
    test('champ vide -> invalidInput SANS appel reseau', () async {
      var called = false;
      final c = LoginController(submit: ({required email, required password}) async {
        called = true;
        return true;
      });

      final r = await c.submit(email: '', password: 'x');

      expect(r, AuthSubmitOutcome.invalidInput);
      expect(called, isFalse, reason: 'pas d appel backend si saisie invalide');
    });

    test('succes -> success', () async {
      final c = LoginController(
          submit: ({required email, required password}) async => true);
      expect(await c.submit(email: 'a@b.co', password: 'secret'),
          AuthSubmitOutcome.success);
      expect(c.loading, isFalse);
    });

    test('backend refuse -> backendError (distinct de validation)', () async {
      final c = LoginController(
          submit: ({required email, required password}) async => false);
      expect(await c.submit(email: 'a@b.co', password: 'secret'),
          AuthSubmitOutcome.backendError);
    });

    test('double soumission : la 2e est ignoree pendant la 1ere', () async {
      var calls = 0;
      final c = LoginController(submit: ({required email, required password}) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      });

      final first = c.submit(email: 'a@b.co', password: 'secret');
      final second = await c.submit(email: 'a@b.co', password: 'secret');

      expect(second, AuthSubmitOutcome.invalidInput);
      await first;
      expect(calls, 1);
    });
  });

  group('RegisterController (#248 C3)', () {
    RegisterController ctrl(RegisterSubmit submit) =>
        RegisterController(submit: submit);
    Future<bool> ok(
            {required email,
            required password,
            required firstName,
            required lastName}) async =>
        true;

    test('mot de passe trop court -> invalidInput SANS appel', () async {
      var called = false;
      final c = ctrl(({required email, required password, required firstName, required lastName}) async {
        called = true;
        return true;
      });

      final r = await c.submit(
          email: 'a@b.co', password: 'abc', firstName: 'J', lastName: 'D');

      expect(r, AuthSubmitOutcome.invalidInput);
      expect(called, isFalse);
    });

    test('champ nom vide -> invalidInput', () async {
      final c = ctrl(ok);
      final r = await c.submit(
          email: 'a@b.co', password: 'abcdef', firstName: '', lastName: 'D');
      expect(r, AuthSubmitOutcome.invalidInput);
    });

    test('saisie valide -> delegue et success', () async {
      final c = ctrl(ok);
      final r = await c.submit(
          email: 'a@b.co', password: 'abcdef', firstName: 'J', lastName: 'D');
      expect(r, AuthSubmitOutcome.success);
    });

    test('indicateur de force suit la saisie', () {
      final c = ctrl(ok);
      c.onPasswordChanged('abc');
      expect(c.passwordStrength, PasswordStrength.weak);
      c.onPasswordChanged('Abcdefgh12!');
      expect(c.passwordStrength, PasswordStrength.strong);
    });
  });
}
