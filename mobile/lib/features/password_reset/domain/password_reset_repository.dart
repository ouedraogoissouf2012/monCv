import '../../../core/error/result.dart';

/// Port de la reinitialisation de mot de passe (issue #381).
///
/// Cote domaine : aucune dependance au transport ni a Flutter. Les deux
/// operations renvoient un [Result] sans valeur — seul le succes/echec compte.
abstract interface class PasswordResetRepository {
  /// Demande l'envoi d'un lien de reinitialisation a [email].
  ///
  /// Le serveur repond de façon uniforme que le compte existe ou non
  /// (anti-enumeration) : un [Result] en succes ne prouve PAS qu'un compte
  /// existe.
  Future<Result<void>> requestReset(String email);

  /// Definit un nouveau mot de passe a partir d'un [token] recu par email.
  ///
  /// Echoue ([Result] en echec) si le jeton est inconnu, expire ou deja utilise.
  Future<Result<void>> confirmReset({
    required String token,
    required String newPassword,
  });
}
