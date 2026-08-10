import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../auth/domain/password_policy.dart';
import '../../auth/presentation/controllers/auth_submit_outcome.dart';

/// Soumission injectee : definit le nouveau mot de passe, renvoie un [Result].
/// Le jeton est capture par l'appelant (issu de la route), pas saisi ici.
typedef ConfirmResetSubmit = Future<Result<void>> Function(String newPassword);

/// Orchestration de l'ecran « nouveau mot de passe » (issue #381).
///
/// Reutilise [PasswordPolicy] (meme politique que l'inscription) pour la
/// validation et l'indicateur de force, valide LOCALEMENT avant tout appel, et
/// distingue erreur locale et erreur backend ([AuthSubmitOutcome]).
class ResetPasswordController extends ChangeNotifier {
  ResetPasswordController({required ConfirmResetSubmit submit})
      : _submit = submit;

  final ConfirmResetSubmit _submit;

  bool _loading = false;
  bool get loading => _loading;

  String _password = '';

  AppException? _lastError;
  AppException? get lastError => _lastError;

  /// Niveau de force du mot de passe courant (indicateur visuel).
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

  /// Tente la reinitialisation. Sans appel reseau si le mot de passe est
  /// invalide. Sans effet si une soumission est deja en cours.
  Future<AuthSubmitOutcome> submit({required String newPassword}) async {
    if (_loading) return AuthSubmitOutcome.invalidInput;
    if (PasswordPolicy.validate(newPassword) != null) {
      return AuthSubmitOutcome.invalidInput;
    }
    _loading = true;
    _lastError = null;
    notifyListeners();

    final result = await _submit(newPassword);
    _loading = false;
    _lastError = result is Failure<void> ? result.exception : null;
    notifyListeners();
    return result is Failure<void>
        ? AuthSubmitOutcome.backendError
        : AuthSubmitOutcome.success;
  }
}
