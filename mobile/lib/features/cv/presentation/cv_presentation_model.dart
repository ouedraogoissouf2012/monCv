import 'dart:ui';

import '../../../models/cv_style.dart';
import '../domain/entities/certification.dart';
import '../domain/entities/cv.dart';
import '../domain/entities/education.dart';
import '../domain/entities/experience.dart';
import '../domain/entities/language.dart';
import '../domain/entities/personal_info.dart';
import '../domain/entities/project.dart';
import '../domain/entities/skill.dart';
import '../domain/value_objects/cv_id.dart';
import '../domain/value_objects/cv_style_ref.dart';

// Re-exporte les entites de domaine que les consommateurs de presentation
// manipulent aux cotes du modele `Cv` (sections, personalInfo, etc.).
export '../domain/entities/certification.dart';
export '../domain/entities/education.dart';
export '../domain/entities/experience.dart';
export '../domain/entities/language.dart';
export '../domain/entities/personal_info.dart';
export '../domain/entities/project.dart';
export '../domain/entities/skill.dart';

/// Modele de presentation `Cv` : facade de compatibilite le temps de la
/// migration Clean Architecture (issue #238).
///
/// Il compose une [CvEntity] pure et un [CvStyle] Flutter (objet de rendu),
/// et expose l'API publique historique attendue par les ecrans/widgets qui
/// n'ont pas encore migre vers [CvEntity]. La conversion `Color <-> int ARGB`
/// entre [CvStyle] et [CvStyleRef] est confinee ici.
///
/// Aucune (de)serialisation JSON n'est exposee : les fichiers data passent
/// desormais par `CvMapper`.
class Cv {
  /// Entite de domaine sous-jacente (source de verite hors style visuel).
  final CvEntity entity;

  /// Style visuel Flutter (presentation), assemble au boundary.
  final CvStyle style;

  Cv({
    int? id,
    required String titre,
    PersonalInfo? personalInfo,
    List<Education> educations = const [],
    List<Experience> experiences = const [],
    List<Skill> skills = const [],
    List<Language> languages = const [],
    List<Certification> certifications = const [],
    List<Project> projects = const [],
    int viewCount = 0,
    int? parentCvId,
    String? varianteLabel,
    int? variantCount,
    String? shareToken,
    bool publicEnabled = false,
    bool publicDownloadsEnabled = false,
    bool publicContactEnabled = false,
    int downloadCount = 0,
    int shareCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.style = CvStyle.defaultStyle,
  })  : entity = CvEntity(
          id: id == null ? null : CvId(id),
          titre: titre,
          personalInfo: personalInfo,
          educations: educations,
          experiences: experiences,
          skills: skills,
          languages: languages,
          certifications: certifications,
          projects: projects,
          viewCount: viewCount,
          parentCvId: parentCvId,
          varianteLabel: varianteLabel,
          variantCount: variantCount,
          shareToken: shareToken,
          publicEnabled: publicEnabled,
          publicDownloadsEnabled: publicDownloadsEnabled,
          publicContactEnabled: publicContactEnabled,
          downloadCount: downloadCount,
          shareCount: shareCount,
          createdAt: createdAt,
          updatedAt: updatedAt,
          style: _styleRefOf(style),
        );

  /// Construit un modele de presentation autour d'une entite de domaine.
  Cv.fromEntity(this.entity, {CvStyle? style})
      : style = style ?? _styleFrom(entity.style);

  int? get id => entity.id?.value;
  String get titre => entity.titre;
  PersonalInfo? get personalInfo => entity.personalInfo;
  List<Education> get educations => entity.educations;
  List<Experience> get experiences => entity.experiences;
  List<Skill> get skills => entity.skills;
  List<Language> get languages => entity.languages;
  List<Certification> get certifications => entity.certifications;
  List<Project> get projects => entity.projects;
  int get viewCount => entity.viewCount;
  int? get parentCvId => entity.parentCvId;
  String? get varianteLabel => entity.varianteLabel;
  int? get variantCount => entity.variantCount;
  String? get shareToken => entity.shareToken;
  bool get publicEnabled => entity.publicEnabled;
  bool get publicDownloadsEnabled => entity.publicDownloadsEnabled;
  bool get publicContactEnabled => entity.publicContactEnabled;
  int get downloadCount => entity.downloadCount;
  int get shareCount => entity.shareCount;
  DateTime? get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;

  /// True si ce CV est une variante adaptee a une offre.
  bool get isVariante => entity.isVariante;

  /// Copie en conservant la semantique HISTORIQUE (`null` = ne pas changer).
  ///
  /// Choix volontaire et transitoire : ce wrapper de compatibilite ne doit pas
  /// changer le comportement observe par les ~34 consommateurs non encore
  /// migres. L'effacement explicite d'un nullable (critere #238) est disponible
  /// sur l'entite de domaine [CvEntity.copyWith] via une sentinelle ; les
  /// consommateurs l'obtiendront en migrant vers `CvEntity`. Aucun appelant
  /// actuel n'efface un champ via `copyWith` (verifie), donc cette limitation
  /// n'introduit aucun bug fonctionnel. Dette suivie par la migration #238.
  Cv copyWith({
    int? id,
    String? titre,
    PersonalInfo? personalInfo,
    List<Education>? educations,
    List<Experience>? experiences,
    List<Skill>? skills,
    List<Language>? languages,
    List<Certification>? certifications,
    List<Project>? projects,
    int? viewCount,
    int? parentCvId,
    String? varianteLabel,
    int? variantCount,
    String? shareToken,
    bool? publicEnabled,
    bool? publicDownloadsEnabled,
    bool? publicContactEnabled,
    int? downloadCount,
    int? shareCount,
    CvStyle? style,
  }) {
    return Cv(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      personalInfo: personalInfo ?? this.personalInfo,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      viewCount: viewCount ?? this.viewCount,
      parentCvId: parentCvId ?? this.parentCvId,
      varianteLabel: varianteLabel ?? this.varianteLabel,
      variantCount: variantCount ?? this.variantCount,
      shareToken: shareToken ?? this.shareToken,
      publicEnabled: publicEnabled ?? this.publicEnabled,
      publicDownloadsEnabled:
          publicDownloadsEnabled ?? this.publicDownloadsEnabled,
      publicContactEnabled: publicContactEnabled ?? this.publicContactEnabled,
      downloadCount: downloadCount ?? this.downloadCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      style: style ?? this.style,
    );
  }

  static CvStyleRef _styleRefOf(CvStyle style) => CvStyleRef(
        templateId: style.templateId,
        fontFamily: style.fontFamily,
        primaryColorArgb: style.primaryColor.toARGB32(),
      );

  static CvStyle _styleFrom(CvStyleRef ref) => CvStyle(
        templateId: ref.templateId,
        primaryColor: Color(ref.primaryColorArgb),
        fontFamily: ref.fontFamily,
      );
}
