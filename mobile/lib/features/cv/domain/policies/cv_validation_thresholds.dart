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

  // ── Seuils de qualite par regle (issue #241) ─────────────────
  /// Longueur minimale conseillee pour un resume professionnel.
  static const int minSummaryLength = 100;

  /// En dessous, on suggere d'ajouter des competences.
  static const int recommendedSkillCount = 5;

  /// Longueur minimale conseillee pour la description d'un projet.
  static const int minProjectDescriptionLength = 30;

  /// Nombre d'items total au-dela duquel le CV risque de deborder d'une page.
  static const int maxItemsBeforeOverflow = 25;

  /// Niveau de competence valide : [minSkillLevel, maxSkillLevel].
  static const int minSkillLevel = 1;
  static const int maxSkillLevel = 5;

  /// Tolerance (jours) au-dela d'aujourd'hui avant de signaler une date future.
  static const int futureDateToleranceDays = 30;
}
