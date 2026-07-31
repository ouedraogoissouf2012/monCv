/// Seuils du score de *qualite/ATS* d'un CV — point unique de verite.
///
/// Depuis l'unification du scoring, un seul bareme qualifie un CV : le score
/// de readiness (100 - deductions) porte par `CvReadinessService`. Ce fichier
/// centralise TOUS ses magic numbers (penalites, seuils de regles, seuils
/// d'affichage) pour qu'aucun ne soit redefini ailleurs (issue #241 / C5 #238,
/// unification post-audit).
abstract final class CvValidationThresholds {
  /// Plafond du bareme (point de depart avant deductions).
  static const int maxScore = 100;

  /// Points retires par erreur bloquante.
  static const int errorPenalty = 15;

  /// Points retires par avertissement qualite.
  static const int warningPenalty = 5;

  /// Score minimal requis pour autoriser l'export du CV.
  static const int exportThreshold = 60;

  /// Score a partir duquel un CV est considere "pret" (recruteur/ATS).
  static const int readyThreshold = 80;

  // ── Seuils d'affichage du score (couleur / libelle) ──────────
  /// Score >= [displayGoodThreshold] : etat "complet" (vert).
  static const int displayGoodThreshold = 80;

  /// Score >= [displayMediumThreshold] : etat "en cours" (orange) ; en dessous,
  /// "incomplet" (rouge).
  static const int displayMediumThreshold = 50;

  /// Barre de progression du formulaire : score >= [progressBarGoodThreshold]
  /// = vert, >= [progressBarMediumThreshold] = orange, en dessous = rouge.
  static const int progressBarGoodThreshold = 70;
  static const int progressBarMediumThreshold = 35;

  // ── Seuils de qualite par regle (issue #241) ─────────────────
  /// Longueur minimale conseillee pour un resume professionnel.
  static const int minSummaryLength = 100;

  /// Longueur minimale conseillee pour la description d'une experience.
  static const int minExperienceDescriptionLength = 80;

  /// En deca, une duree de formation parait incoherente (jours).
  static const int suspiciousEducationDurationDays = 45;

  /// Nombre de cliches toleres dans le resume avant de le signaler.
  static const int maxTolerableCliches = 2;

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
