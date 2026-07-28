/// Resultat typé d'une amelioration IA d'un CV (endpoint `/ai/enhance-cv`).
///
/// Entité de domaine : Dart pur, sans Flutter, HTTP ni JSON. La conversion
/// depuis le payload backend est faite par la couche `data` (DTO + mapper).
class EnhancedCv {
  final String? titrePoste;
  final String? resumeProfessionnel;
  final String? titreOffre;
  final List<EnhancedExperience> experiences;
  final List<EnhancedEducation> educations;
  final List<EnhancedSkill> skills;
  final List<EnhancedLanguage> languages;
  final List<EnhancedCertification> certifications;
  final List<EnhancedProject> projects;
  final List<String> warnings;
  final int correctionCount;
  final bool aiGenerated;
  final bool fallback;
  final String? level;

  const EnhancedCv({
    this.titrePoste,
    this.resumeProfessionnel,
    this.titreOffre,
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.projects = const [],
    this.warnings = const [],
    this.correctionCount = 0,
    this.aiGenerated = false,
    this.fallback = false,
    this.level,
  });
}

/// Experience professionnelle amelioree.
class EnhancedExperience {
  final int? id;
  final String? poste;
  final String? description;
  const EnhancedExperience({this.id, this.poste, this.description});
}

/// Formation amelioree.
class EnhancedEducation {
  final int? id;
  final String? etablissement;
  final String? diplome;
  final String? domaine;
  final String? description;
  const EnhancedEducation({
    this.id,
    this.etablissement,
    this.diplome,
    this.domaine,
    this.description,
  });
}

/// Competence amelioree.
class EnhancedSkill {
  final String? nom;
  final int? niveau;
  const EnhancedSkill({this.nom, this.niveau});
}

/// Langue amelioree.
class EnhancedLanguage {
  final int? id;
  final String? langue;
  const EnhancedLanguage({this.id, this.langue});
}

/// Certification amelioree.
class EnhancedCertification {
  final int? id;
  final String? nom;
  final String? organisme;
  const EnhancedCertification({this.id, this.nom, this.organisme});
}

/// Projet ameliore.
class EnhancedProject {
  final int? id;
  final String? nom;
  final String? description;
  final String? technologies;
  const EnhancedProject({
    this.id,
    this.nom,
    this.description,
    this.technologies,
  });
}
