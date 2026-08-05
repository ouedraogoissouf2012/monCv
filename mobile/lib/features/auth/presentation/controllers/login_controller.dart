import 'package:flutter/foundation.dart';

import 'auth_submit_outcome.dart';

/// Fonction de connexion injectee (deleguee a AuthProvider) : `true` si succes.
typedef LoginSubmit = Future<bool> Function({
  required String email,
  required String password,
});

/// Orchestration de l'ecran de connexion (issue #248, C3).
///
/// Validation LOCALE (champs non vides) avant tout appel reseau, etat de
/// chargement et resultat TYPE (validation locale vs erreur backend). La
/// soumission reelle est deleguee a [LoginSubmit] (AuthProvider) — aucun
/// changement du contrat d'auth.
class LoginController extends ChangeNotifier {
  LoginController({required LoginSubmit submit}) : _submit = submit;

  final LoginSubmit _submit;

  bool _loading = false;
  bool get loading => _loading;

  /// Tente la connexion. Sans appel reseau si un champ est vide. Sans effet si
  /// une soumission est deja en cours.
  Future<AuthSubmitOutcome> submit({
    required String email,
    required String password,
  }) async {
    if (_loading) return AuthSubmitOutcome.invalidInput;
    if (email.trim().isEmpty || password.isEmpty) {
      return AuthSubmitOutcome.invalidInput;
    }
    _loading = true;
    notifyListeners();

    final ok = await _submit(email: email.trim(), password: password);
    _loading = false;
    notifyListeners();
    return ok ? AuthSubmitOutcome.success : AuthSubmitOutcome.backendError;
  }
}
