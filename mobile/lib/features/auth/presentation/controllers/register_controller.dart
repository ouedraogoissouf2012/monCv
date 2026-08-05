import 'package:flutter/foundation.dart';

import '../../domain/password_policy.dart';
import 'auth_submit_outcome.dart';

/// Fonction d'inscription injectee (deleguee a AuthProvider) : retourne `true`
/// en cas de succes, `false` sinon.
typedef RegisterSubmit = Future<bool> Function({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
});

/// Orchestration de l'ecran d'inscription (issue #248, C3).
///
/// Gere la force du mot de passe (via [PasswordPolicy]), la validation LOCALE
/// avant tout appel reseau, l'etat de chargement et un resultat TYPE
/// distinguant erreur de validation locale et erreur backend (crit. #248). Ne
/// touche pas au contrat d'auth : la soumission reelle est deleguee a
/// [RegisterSubmit] (AuthProvider).
class RegisterController extends ChangeNotifier {
  RegisterController({required RegisterSubmit submit}) : _submit = submit;

  final RegisterSubmit _submit;

  bool _loading = false;
  String _password = '';

  bool get loading => _loading;

  /// Niveau de force du mot de passe courant (pour l'indicateur visuel).
  PasswordStrength get passwordStrength =>
      PasswordPolicy.strengthOf(_password);

  double get passwordScore => PasswordPolicy.score(_password);

  /// Met a jour le mot de passe suivi (pour l'indicateur de force).
  void onPasswordChanged(String value) {
    if (value == _password) return;
    _password = value;
    notifyListeners();
  }

  /// Erreur de validation du mot de passe, ou `null` s'il est conforme.
  PasswordRuleError? validatePassword(String? value) =>
      PasswordPolicy.validate(value);

  /// Tente l'inscription. Valide d'abord LOCALEMENT (pas d'appel reseau si
  /// invalide), puis delegue. Sans effet si une soumission est deja en cours.
  Future<AuthSubmitOutcome> submit({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    if (_loading) return AuthSubmitOutcome.invalidInput;
    if (email.trim().isEmpty ||
        firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        PasswordPolicy.validate(password) != null) {
      return AuthSubmitOutcome.invalidInput;
    }
    _loading = true;
    notifyListeners();

    final ok = await _submit(
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    _loading = false;
    notifyListeners();
    return ok ? AuthSubmitOutcome.success : AuthSubmitOutcome.backendError;
  }
}
