/// DTO du payload backend `EnhanceCvResponse` (endpoint `/ai/enhance-cv`).
///
/// Seule couche autorisee a manipuler `Map<String, dynamic>`. Aucune logique
/// metier : uniquement le decodage JSON defensif. Le mapper convertit ensuite
/// vers l'entité de domaine `EnhancedCv`.
class EnhancedCvDto {
  final String? titrePoste;
  final String? resumeProfessionnel;
  final String? titreOffre;
  final List<ExperienceEnhancementDto> experiences;
  final List<EducationEnhancementDto> educations;
  final List<SkillEnhancementDto> skills;
  final List<LanguageEnhancementDto> languages;
  final List<CertificationEnhancementDto> certifications;
  final List<ProjectEnhancementDto> projects;
  final List<String> warnings;
  final int correctionCount;
  final bool aiGenerated;
  final bool fallback;
  final String? level;

  const EnhancedCvDto({
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

  factory EnhancedCvDto.fromJson(Map<String, dynamic> json) => EnhancedCvDto(
        titrePoste: json['titrePoste'] as String?,
        resumeProfessionnel: json['resumeProfessionnel'] as String?,
        titreOffre: json['titreOffre'] as String?,
        experiences: _list(json['experiences'], ExperienceEnhancementDto.fromJson),
        educations: _list(json['educations'], EducationEnhancementDto.fromJson),
        skills: _list(json['skills'], SkillEnhancementDto.fromJson),
        languages: _list(json['languages'], LanguageEnhancementDto.fromJson),
        certifications:
            _list(json['certifications'], CertificationEnhancementDto.fromJson),
        projects: _list(json['projects'], ProjectEnhancementDto.fromJson),
        warnings: _stringList(json['warnings']),
        correctionCount: json['correctionCount'] as int? ?? 0,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
        fallback: json['fallback'] as bool? ?? false,
        level: json['level'] as String?,
      );
}

/// Decode une liste JSON en list de DTO via [fromJson], en ignorant les
/// elements non-Map (defensif vis-a-vis d'un payload malforme).
List<T> _list<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList(growable: false);
}

class ExperienceEnhancementDto {
  final int? id;
  final String? poste;
  final String? description;
  const ExperienceEnhancementDto({this.id, this.poste, this.description});

  factory ExperienceEnhancementDto.fromJson(Map<String, dynamic> json) =>
      ExperienceEnhancementDto(
        id: (json['id'] as num?)?.toInt(),
        poste: json['poste'] as String?,
        description: json['description'] as String?,
      );
}

class EducationEnhancementDto {
  final int? id;
  final String? etablissement;
  final String? diplome;
  final String? domaine;
  final String? description;
  const EducationEnhancementDto({
    this.id,
    this.etablissement,
    this.diplome,
    this.domaine,
    this.description,
  });

  factory EducationEnhancementDto.fromJson(Map<String, dynamic> json) =>
      EducationEnhancementDto(
        id: (json['id'] as num?)?.toInt(),
        etablissement: json['etablissement'] as String?,
        diplome: json['diplome'] as String?,
        domaine: json['domaine'] as String?,
        description: json['description'] as String?,
      );
}

class SkillEnhancementDto {
  final String? nom;
  final int? niveau;
  const SkillEnhancementDto({this.nom, this.niveau});

  factory SkillEnhancementDto.fromJson(Map<String, dynamic> json) =>
      SkillEnhancementDto(
        nom: json['nom'] as String?,
        niveau: (json['niveau'] as num?)?.toInt(),
      );
}

class LanguageEnhancementDto {
  final int? id;
  final String? langue;
  const LanguageEnhancementDto({this.id, this.langue});

  factory LanguageEnhancementDto.fromJson(Map<String, dynamic> json) =>
      LanguageEnhancementDto(
        id: (json['id'] as num?)?.toInt(),
        langue: json['langue'] as String?,
      );
}

class CertificationEnhancementDto {
  final int? id;
  final String? nom;
  final String? organisme;
  const CertificationEnhancementDto({this.id, this.nom, this.organisme});

  factory CertificationEnhancementDto.fromJson(Map<String, dynamic> json) =>
      CertificationEnhancementDto(
        id: (json['id'] as num?)?.toInt(),
        nom: json['nom'] as String?,
        organisme: json['organisme'] as String?,
      );
}

class ProjectEnhancementDto {
  final int? id;
  final String? nom;
  final String? description;
  final String? technologies;
  const ProjectEnhancementDto({
    this.id,
    this.nom,
    this.description,
    this.technologies,
  });

  factory ProjectEnhancementDto.fromJson(Map<String, dynamic> json) =>
      ProjectEnhancementDto(
        id: (json['id'] as num?)?.toInt(),
        nom: json['nom'] as String?,
        description: json['description'] as String?,
        technologies: json['technologies'] as String?,
      );
}
