/// Sentinelle partagee par les `copyWith` des entites du domaine CV.
///
/// Probleme resolu : avec le pattern classique `valeur ?? this.champ`, passer
/// `null` a un `copyWith` ne peut pas distinguer « ne pas changer » de
/// « effacer explicitement ». Les entites utilisent donc, pour chaque champ
/// nullable, un parametre `Object? champ = unsetSentinel` puis :
///
/// ```dart
/// champ: identical(champ, unsetSentinel) ? this.champ : champ as T?,
/// ```
///
/// Ainsi `copyWith()` conserve la valeur, `copyWith(champ: null)` l'efface, et
/// `copyWith(champ: x)` la remplace — sans ambiguite.
///
/// Instance unique (comparee par `identical`), volontairement privee au package
/// via l'export du domaine.
const Object unsetSentinel = _UnsetSentinel();

class _UnsetSentinel {
  const _UnsetSentinel();
}

/// Egalite structurelle de deux listes (meme longueur, elements egaux dans
/// l'ordre). Helper pur Dart pour les `==` des entites portant des collections,
/// sans dependre de `package:flutter/foundation` (interdit dans le domaine).
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

