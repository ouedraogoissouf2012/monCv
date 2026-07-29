/// Severite d'un resultat de validation (issue #241).
///
/// Distinction typee entre ce qui bloque, ce qui degrade la qualite et ce qui
/// informe — remplace la separation implicite `errors`/`warnings` du validator.
enum ValidationSeverity {
  /// Bloque une action (ex. sauvegarde impossible).
  error,

  /// N'empeche rien mais signale un defaut de qualite.
  warning,

  /// Information neutre.
  info,
}

/// Code stable et exhaustif d'un resultat de validation CV (issue #241).
///
/// Chaque regle produit un [ValidationCode] (jamais un message traduit) ; la
/// traduction vit dans un mapper de presentation. Un code = une intention de
/// validation, independante de la langue et de Flutter.
enum ValidationCode {
  // ── Identite / profil ────────────────────────────────────────
  personalInfoMissing,
  personalInfoIncomplete,
  cvTitleRequired,
  requiredFieldMissing,
  jobTitleMissing,
  invalidEmail,
  summaryEmpty,
  summaryShort,
  techLinkMissing,

  // ── Experiences ──────────────────────────────────────────────
  noExperience,
  descriptionMissing,
  noMetric,
  endBeforeStart,
  futureEnd,
  companyRequired,
  startDateRequired,

  // ── Formations ───────────────────────────────────────────────
  noEducation,
  establishmentRequired,
  degreeRequired,

  // ── Competences ──────────────────────────────────────────────
  noSkills,
  fewSkills,
  combinedSkills,
  skillLevelOutOfRange,

  // ── Langues ──────────────────────────────────────────────────
  noLanguages,
  languageNameRequired,
  languageLevelRequired,

  // ── Certifications ───────────────────────────────────────────
  futureCertification,
  certificationExpirationBeforeIssue,
  certificationNameRequired,

  // ── Projets ──────────────────────────────────────────────────
  shortProject,
  projectNameRequired,

  // ── Global ───────────────────────────────────────────────────
  tooMuchContent,
}
