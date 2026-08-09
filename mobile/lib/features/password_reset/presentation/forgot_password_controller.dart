import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../auth/presentation/controllers/auth_submit_outcome.dart';

/// Soumission injectee : demande d'envoi du lien, renvoie un [Result] typé.
typedef RequestResetSubmit = Future<Result<void>> Function(String email);

/// Orchestration de l'ecran « mot de passe oublie » (issue #381).
///
/// Validation LOCALE (email non vide + `@`) avant tout appel reseau, etat de
/// chargement et resultat TYPE ([AuthSubmitOutcome]). La soumission reelle est
/// deleguee (use case). Cote serveur la reponse est uniforme que l'email existe
/// ou non : un succes ne prouve donc PAS l'existence d'un compte.
class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({required RequestResetSubmit submit})
      : _submit = submit;

  final RequestResetSubmit _submit;

  bool _loading = false;
  bool get loading => _loading;

  AppException? _lastError;

  /// Derniere erreur backend/reseau (pour l'affichage), ou `null`.
  AppException? get lastError => _lastError;

  /// Tente l'envoi. Sans appel reseau si l'email est vide ou sans `@`. Sans
  /// effet si une soumission est deja en cours.
  Future<AuthSubmitOutcome> submit(String email) async {
    if (_loading) return AuthSubmitOutcome.invalidInput;
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return AuthSubmitOutcome.invalidInput;
    }
    _loading = true;
    _lastError = null;
    notifyListeners();

    final result = await _submit(trimmed);
    _loading = false;
    _lastError = result is Failure<void> ? result.exception : null;
    notifyListeners();
    return result is Failure<void>
        ? AuthSubmitOutcome.backendError
        : AuthSubmitOutcome.success;
  }
}
