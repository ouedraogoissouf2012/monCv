/// Seuils du score de *validation* (qualite) d'un CV.
///
/// Distincts du score de *completion* (presence des sections) porte par
/// [CvCompletionPolicy] : ici on mesure la qualite via un bareme par
/// deductions. Regroupes dans cette politique nommee pour supprimer les magic
/// numbers disperses dans `CvValidator`, les formulaires et `CvCard`
/// (issue #241 / critere C5 de #238).
abstract final class CvValidationThresholds {
  /// Plafond du bareme (point de depart avant deductions).
  static const int maxScore = 100;

  /// Points retires par erreur bloquante.
  static const int errorPenalty = 15;

  /// Points retires par avertissement qualite.
  static const int warningPenalty = 5;

  /// Score minimal requis pour autoriser l'export du CV.
  static const int exportThreshold = 60;
}
