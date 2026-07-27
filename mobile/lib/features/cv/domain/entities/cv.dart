import '../value_objects/cv_id.dart';
import '../value_objects/cv_style_ref.dart';
import 'certification.dart';
import 'copy_with_sentinel.dart';
import 'education.dart';
import 'experience.dart';
import 'language.dart';
import 'personal_info.dart';
import 'project.dart';
import 'skill.dart';

/// Entite racine du domaine CV : immuable, pure (aucune dependance Flutter,
/// HTTP ou JSON), avec collections copiees defensivement et non modifiables.
///
/// La (de)serialisation et le calcul de completion vivent hors de l'entite
/// (respectivement dans `data/` et `domain/policies/`).
final class CvEntity {
  final CvId? id;
  final String titre;
  final PersonalInfo? personalInfo;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Certification> certifications;
  final List<Project> projects;
  final int viewCount;
  final int? parentCvId;
  final String? varianteLabel;
  final int? variantCount;
  final String? shareToken;
  final bool publicEnabled;
  final bool publicDownloadsEnabled;
  final bool publicContactEnabled;
  final int downloadCount;
  final int shareCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CvStyleRef style;

  CvEntity({
    this.id,
    required this.titre,
    this.personalInfo,
    List<Education> educations = const [],
    List<Experience> experiences = const [],
    List<Skill> skills = const [],
    List<Language> languages = const [],
    List<Certification> certifications = const [],
    List<Project> projects = const [],
    this.viewCount = 0,
    this.parentCvId,
    this.varianteLabel,
    this.variantCount,
    this.shareToken,
    this.publicEnabled = false,
    this.publicDownloadsEnabled = false,
    this.publicContactEnabled = false,
    this.downloadCount = 0,
    this.shareCount = 0,
    this.createdAt,
    this.updatedAt,
    this.style = CvStyleRef.fallback,
  })  : educations = List.unmodifiable(educations),
        experiences = List.unmodifiable(experiences),
        skills = List.unmodifiable(skills),
        languages = List.unmodifiable(languages),
        certifications = List.unmodifiable(certifications),
        projects = List.unmodifiable(projects);

  /// True si ce CV est une variante adaptee a une offre.
  bool get isVariante => varianteLabel != null;

  CvEntity copyWith({
    Object? id = unsetSentinel,
    String? titre,
    Object? personalInfo = unsetSentinel,
    List<Education>? educations,
    List<Experience>? experiences,
    List<Skill>? skills,
    List<Language>? languages,
    List<Certification>? certifications,
    List<Project>? projects,
    int? viewCount,
    Object? parentCvId = unsetSentinel,
    Object? varianteLabel = unsetSentinel,
    Object? variantCount = unsetSentinel,
    Object? shareToken = unsetSentinel,
    bool? publicEnabled,
    bool? publicDownloadsEnabled,
    bool? publicContactEnabled,
    int? downloadCount,
    int? shareCount,
    Object? createdAt = unsetSentinel,
    Object? updatedAt = unsetSentinel,
    CvStyleRef? style,
  }) {
    return CvEntity(
      id: identical(id, unsetSentinel) ? this.id : id as CvId?,
      titre: titre ?? this.titre,
      personalInfo: identical(personalInfo, unsetSentinel)
          ? this.personalInfo
          : personalInfo as PersonalInfo?,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      viewCount: viewCount ?? this.viewCount,
      parentCvId: identical(parentCvId, unsetSentinel)
          ? this.parentCvId
          : parentCvId as int?,
      varianteLabel: identical(varianteLabel, unsetSentinel)
          ? this.varianteLabel
          : varianteLabel as String?,
      variantCount: identical(variantCount, unsetSentinel)
          ? this.variantCount
          : variantCount as int?,
      shareToken: identical(shareToken, unsetSentinel)
          ? this.shareToken
          : shareToken as String?,
      publicEnabled: publicEnabled ?? this.publicEnabled,
      publicDownloadsEnabled:
          publicDownloadsEnabled ?? this.publicDownloadsEnabled,
      publicContactEnabled: publicContactEnabled ?? this.publicContactEnabled,
      downloadCount: downloadCount ?? this.downloadCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: identical(createdAt, unsetSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, unsetSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CvEntity &&
      other.id == id &&
      other.titre == titre &&
      other.personalInfo == personalInfo &&
      listEquals(other.educations, educations) &&
      listEquals(other.experiences, experiences) &&
      listEquals(other.skills, skills) &&
      listEquals(other.languages, languages) &&
      listEquals(other.certifications, certifications) &&
      listEquals(other.projects, projects) &&
      other.viewCount == viewCount &&
      other.parentCvId == parentCvId &&
      other.varianteLabel == varianteLabel &&
      other.variantCount == variantCount &&
      other.shareToken == shareToken &&
      other.publicEnabled == publicEnabled &&
      other.publicDownloadsEnabled == publicDownloadsEnabled &&
      other.publicContactEnabled == publicContactEnabled &&
      other.downloadCount == downloadCount &&
      other.shareCount == shareCount &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.style == style;

  @override
  int get hashCode => Object.hashAll([
        id,
        titre,
        personalInfo,
        Object.hashAll(educations),
        Object.hashAll(experiences),
        Object.hashAll(skills),
        Object.hashAll(languages),
        Object.hashAll(certifications),
        Object.hashAll(projects),
        viewCount,
        parentCvId,
        varianteLabel,
        variantCount,
        shareToken,
        publicEnabled,
        publicDownloadsEnabled,
        publicContactEnabled,
        downloadCount,
        shareCount,
        createdAt,
        updatedAt,
        style,
      ]);
}
