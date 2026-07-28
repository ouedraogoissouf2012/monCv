import 'dart:convert';

import '../../domain/entities/cv.dart';
import '../../domain/value_objects/cv_id.dart';
import '../dto/cv_style_dto.dart';
import 'cv_section_mapper.dart';
import 'json_codec_helpers.dart';

/// Version courante du schema de cache local des CV.
const int kCvCacheSchemaVersion = 1;

/// Convertit un CV entre ses representations JSON et l'entite de domaine.
///
/// Deux formats distincts :
/// - **Reseau** ([fromNetworkJson]/[toNetworkJson]) : miroir du contrat backend.
///   L'ecriture est volontairement minimale (le serveur ignore les metadonnees
///   qu'il calcule lui-meme) ; la lecture mappe la cle `publicToken` vers
///   `shareToken` et deduit `publicEnabled`.
/// - **Cache local** ([fromCacheJson]/[toCacheJson]) : enveloppe versionnee
///   `{schemaVersion, data}` **sans perte** (toutes les metadonnees preservees),
///   avec migration des anciens formats et tolerance aux donnees corrompues.
final class CvMapper {
  const CvMapper();

  static const CvSectionMapper _sections = CvSectionMapper();
  static const CvStyleDto _style = CvStyleDto();

  // ─────────────────────────── Reseau ───────────────────────────

  CvEntity fromNetworkJson(Map<String, dynamic> json) {
    final token = asString(json['publicToken']);
    return CvEntity(
      id: _idFrom(json['id']),
      titre: asString(json['titre']) ?? '',
      personalInfo: json['personalInfo'] is Map<String, dynamic>
          ? _sections.personalInfoFromJson(
              json['personalInfo'] as Map<String, dynamic>)
          : null,
      educations: _sections.educationsFromJson(json['educations']),
      experiences: _sections.experiencesFromJson(json['experiences']),
      skills: _sections.skillsFromJson(json['skills']),
      languages: _sections.languagesFromJson(json['languages']),
      certifications: _sections.certificationsFromJson(json['certifications']),
      projects: _sections.projectsFromJson(json['projects']),
      viewCount: asInt(json['viewCount']) ?? 0,
      parentCvId: asInt(json['parentCvId']),
      varianteLabel: asString(json['varianteLabel']),
      variantCount: asInt(json['variantCount']),
      shareToken: token,
      publicEnabled: asBool(json['publicEnabled'], orElse: token != null),
      publicDownloadsEnabled: asBool(json['publicDownloadsEnabled']),
      publicContactEnabled: asBool(json['publicContactEnabled']),
      downloadCount: asInt(json['downloadCount']) ?? 0,
      shareCount: asInt(json['shareCount']) ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      style: _style.fromJson(json['style']),
    );
  }

  /// Format minimal envoye au serveur en creation/mise a jour. Les metadonnees
  /// gerees cote serveur (compteurs, token de partage, dates) sont omises.
  Map<String, dynamic> toNetworkJson(CvEntity cv) => {
        if (cv.id != null) 'id': cv.id!.value,
        'titre': cv.titre,
        'personalInfo': cv.personalInfo == null
            ? null
            : _sections.personalInfoToJson(cv.personalInfo!),
        'educations':
            cv.educations.map(_sections.educationToJson).toList(),
        'experiences':
            cv.experiences.map(_sections.experienceToJson).toList(),
        'skills': cv.skills.map(_sections.skillToJson).toList(),
        'languages': cv.languages.map(_sections.languageToJson).toList(),
        'certifications':
            cv.certifications.map(_sections.certificationToJson).toList(),
        'projects': cv.projects.map(_sections.projectToJson).toList(),
        'style': _style.toJson(cv.style),
      };

  // ─────────────────────────── Cache ────────────────────────────

  /// Serialise une liste de CV dans l'enveloppe versionnee courante.
  String toCacheJson(List<CvEntity> cvs) => jsonEncode({
        'schemaVersion': kCvCacheSchemaVersion,
        'data': cvs.map(_toCacheMap).toList(),
      });

  /// Deserialise le cache local, en migrant les anciens formats.
  ///
  /// Retourne `null` quand le cache est **illisible ou incompatible** (JSON
  /// corrompu, forme inattendue, version de schema future inconnue) afin que
  /// l'appelant puisse le distinguer d'un cache **legitimement vide** (`[]`) et
  /// ne pas masquer une erreur reseau derriere une liste vide. Les items
  /// individuels malformes d'un blob par ailleurs valide restent ignores
  /// (best-effort). Ne propage jamais d'exception.
  List<CvEntity>? fromCacheJson(String raw) {
    if (raw.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    // Format legacy : liste brute au format reseau minimal (schemaVersion 0).
    if (decoded is List) return _decodeItems(decoded);
    if (decoded is Map<String, dynamic>) {
      final version = asInt(decoded['schemaVersion']);
      if (version == null || version > kCvCacheSchemaVersion) return null;
      final data = decoded['data'];
      if (data is! List) return null;
      return _decodeItems(data);
    }
    return null;
  }

  /// Serialise un CV isole pour la file de synchronisation offline (meme schema
  /// versionne, sans perte).
  String cvToCacheString(CvEntity cv) => jsonEncode({
        'schemaVersion': kCvCacheSchemaVersion,
        'data': _toCacheMap(cv),
      });

  /// Deserialise un CV isole depuis la file offline, ou `null` si corrompu.
  CvEntity? cvFromCacheString(String raw) {
    if (raw.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final version = asInt(decoded['schemaVersion']);
    if (version == null || version > kCvCacheSchemaVersion) return null;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) return null;
    return _fromCacheMap(data);
  }

  // ────────────────────────── Internes ──────────────────────────

  List<CvEntity> _decodeItems(List<dynamic> rawItems) {
    final cvs = <CvEntity>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) cvs.add(_fromCacheMap(item));
    }
    return cvs;
  }

  /// Map cache -> entite. Le cache stocke la cle `shareToken` en clair (schema
  /// local libre) mais reste compatible avec un blob legacy en `publicToken`.
  CvEntity _fromCacheMap(Map<String, dynamic> json) {
    final token = asString(json['shareToken']) ?? asString(json['publicToken']);
    return CvEntity(
      id: _idFrom(json['id']),
      titre: asString(json['titre']) ?? '',
      personalInfo: json['personalInfo'] is Map<String, dynamic>
          ? _sections.personalInfoFromJson(
              json['personalInfo'] as Map<String, dynamic>)
          : null,
      educations: _sections.educationsFromJson(json['educations']),
      experiences: _sections.experiencesFromJson(json['experiences']),
      skills: _sections.skillsFromJson(json['skills']),
      languages: _sections.languagesFromJson(json['languages']),
      certifications: _sections.certificationsFromJson(json['certifications']),
      projects: _sections.projectsFromJson(json['projects']),
      viewCount: asInt(json['viewCount']) ?? 0,
      parentCvId: asInt(json['parentCvId']),
      varianteLabel: asString(json['varianteLabel']),
      variantCount: asInt(json['variantCount']),
      shareToken: token,
      publicEnabled: asBool(json['publicEnabled'], orElse: token != null),
      publicDownloadsEnabled: asBool(json['publicDownloadsEnabled']),
      publicContactEnabled: asBool(json['publicContactEnabled']),
      downloadCount: asInt(json['downloadCount']) ?? 0,
      shareCount: asInt(json['shareCount']) ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      style: _style.fromJson(json['style']),
    );
  }

  /// Entite -> map cache, symetrique et complet (aucune perte).
  Map<String, dynamic> _toCacheMap(CvEntity cv) => {
        'id': cv.id?.value,
        'titre': cv.titre,
        'personalInfo': cv.personalInfo == null
            ? null
            : _sections.personalInfoToJson(cv.personalInfo!),
        'educations': cv.educations.map(_sections.educationToJson).toList(),
        'experiences': cv.experiences.map(_sections.experienceToJson).toList(),
        'skills': cv.skills.map(_sections.skillToJson).toList(),
        'languages': cv.languages.map(_sections.languageToJson).toList(),
        'certifications':
            cv.certifications.map(_sections.certificationToJson).toList(),
        'projects': cv.projects.map(_sections.projectToJson).toList(),
        'viewCount': cv.viewCount,
        'parentCvId': cv.parentCvId,
        'varianteLabel': cv.varianteLabel,
        'variantCount': cv.variantCount,
        'shareToken': cv.shareToken,
        'publicEnabled': cv.publicEnabled,
        'publicDownloadsEnabled': cv.publicDownloadsEnabled,
        'publicContactEnabled': cv.publicContactEnabled,
        'downloadCount': cv.downloadCount,
        'shareCount': cv.shareCount,
        'createdAt': cv.createdAt?.toIso8601String(),
        'updatedAt': cv.updatedAt?.toIso8601String(),
        'style': _style.toJson(cv.style),
      };

  CvId? _idFrom(Object? raw) {
    final value = asInt(raw);
    return value == null ? null : CvId(value);
  }
}
