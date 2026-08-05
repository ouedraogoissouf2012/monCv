/// Niveau de force d'un mot de passe (issue #248, C1).
///
/// Enum neutre : la presentation mappe chaque niveau vers un libelle localise
/// et une couleur du design system. Le domaine ne connait ni Flutter ni couleur.
enum PasswordStrength { weak, medium, good, strong }

/// Erreur de validation d'un mot de passe a la soumission (code neutre).
enum PasswordRuleError { empty, tooShort }

/// Politique de mot de passe PURE (issue #248, C1).
///
/// Regroupe la regle de longueur minimale (validation a la soumission) et le
/// calcul de force (indicateur visuel). Reproduit a l'identique la logique
/// dispersee dans register_screen.dart (`_checkPasswordStrength`, validator).
/// Dart pur, testable, sans dependance UI.
abstract final class PasswordPolicy {
  /// Longueur minimale exigee pour s'inscrire.
  static const int minLength = 6;

  /// Valide un mot de passe pour la soumission. Retourne `null` si valide,
  /// sinon le code d'erreur (la presentation le mappe vers un message localise).
  static PasswordRuleError? validate(String? password) {
    if (password == null || password.isEmpty) return PasswordRuleError.empty;
    if (password.length < minLength) return PasswordRuleError.tooShort;
    return null;
  }

  /// Score de force dans [0, 1], cumulant longueur et diversite de caracteres.
  static double score(String password) {
    var strength = 0.0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    return strength.clamp(0.0, 1.0);
  }

  /// Niveau de force derive du [score] (memes seuils que le monolithe).
  static PasswordStrength strengthOf(String password) {
    final s = score(password);
    if (s < 0.3) return PasswordStrength.weak;
    if (s < 0.6) return PasswordStrength.medium;
    if (s < 0.8) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}
