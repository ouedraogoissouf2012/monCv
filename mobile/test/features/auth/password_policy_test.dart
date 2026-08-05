import 'package:cv_mobile/features/auth/domain/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validate (#248 C1)', () {
    test('vide ou null -> empty', () {
      expect(PasswordPolicy.validate(null), PasswordRuleError.empty);
      expect(PasswordPolicy.validate(''), PasswordRuleError.empty);
    });

    test('trop court (< 6) -> tooShort', () {
      expect(PasswordPolicy.validate('abc'), PasswordRuleError.tooShort);
      expect(PasswordPolicy.validate('12345'), PasswordRuleError.tooShort);
    });

    test('exactement 6 caracteres -> valide', () {
      expect(PasswordPolicy.validate('abcdef'), isNull);
    });

    test('au-dela du minimum -> valide', () {
      expect(PasswordPolicy.validate('MotDePasse123!'), isNull);
    });
  });

  group('score (#248 C1)', () {
    test('vide -> 0', () {
      expect(PasswordPolicy.score(''), 0.0);
    });

    test('borne a 1 pour un mot de passe complet', () {
      // Longueur >=12 + maj + min + chiffre + special = plafond.
      expect(PasswordPolicy.score('Abcdefgh123!@#'), 1.0);
    });

    test('score croissant avec la diversite', () {
      expect(PasswordPolicy.score('abcdef') <
          PasswordPolicy.score('Abcdef1!'), isTrue);
    });
  });

  group('strengthOf - seuils (#248 C1)', () {
    test('court et simple -> weak', () {
      expect(PasswordPolicy.strengthOf('abc'), PasswordStrength.weak);
    });

    test('mot de passe complet -> strong', () {
      expect(PasswordPolicy.strengthOf('Abcdefgh123!@#'),
          PasswordStrength.strong);
    });

    test('couvre les 4 niveaux selon la complexite', () {
      // weak (<0.3), medium (<0.6), good (<0.8), strong (>=0.8).
      expect(PasswordPolicy.strengthOf('ab'), PasswordStrength.weak);
      expect(PasswordPolicy.strengthOf('abcdef'), PasswordStrength.medium);
      expect(PasswordPolicy.strengthOf('Abcdef12'), PasswordStrength.good);
      expect(PasswordPolicy.strengthOf('Abcdefgh12!'),
          PasswordStrength.strong);
    });
  });
}
