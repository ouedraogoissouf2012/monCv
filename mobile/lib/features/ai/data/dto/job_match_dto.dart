/// DTO du payload backend `JobMatchResponse` (endpoint `/ai/match-job`).
///
/// Seule couche autorisee a manipuler `Map<String, dynamic>`. Le mapper
/// convertit vers l'entité de domaine `JobMatch`.
class JobMatchDto {
  final int score;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> suggestions;
  final List<CategoryScoreDto> categories;
  final List<PrioritizedRecommendationDto> prioritizedRecommendations;
  final List<FormatCheckDto> formatChecks;
  final String? optimizedResume;
  final bool aiGenerated;
  final bool fallback;

  const JobMatchDto({
    this.score = 0,
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
    this.suggestions = const [],
    this.categories = const [],
    this.prioritizedRecommendations = const [],
    this.formatChecks = const [],
    this.optimizedResume,
    this.aiGenerated = false,
    this.fallback = false,
  });

  factory JobMatchDto.fromJson(Map<String, dynamic> json) => JobMatchDto(
        score: (json['score'] as num?)?.toInt() ?? 0,
        matchedKeywords: _stringList(json['matchedKeywords']),
        missingKeywords: _stringList(json['missingKeywords']),
        suggestions: _stringList(json['suggestions']),
        categories: _list(json['categories'], CategoryScoreDto.fromJson),
        prioritizedRecommendations: _list(
          json['prioritizedRecommendations'],
          PrioritizedRecommendationDto.fromJson,
        ),
        formatChecks: _list(json['formatChecks'], FormatCheckDto.fromJson),
        optimizedResume: json['optimizedResume'] as String?,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
        fallback: json['fallback'] as bool? ?? false,
      );
}

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

class CategoryScoreDto {
  final String? key;
  final String? label;
  final int score;
  final String? summary;
  final List<String> evidence;
  const CategoryScoreDto({
    this.key,
    this.label,
    this.score = 0,
    this.summary,
    this.evidence = const [],
  });

  factory CategoryScoreDto.fromJson(Map<String, dynamic> json) =>
      CategoryScoreDto(
        key: json['key'] as String?,
        label: json['label'] as String?,
        score: (json['score'] as num?)?.toInt() ?? 0,
        summary: json['summary'] as String?,
        evidence: _stringList(json['evidence']),
      );
}

class PrioritizedRecommendationDto {
  final int priority;
  final String? title;
  final String? description;
  final List<String> keywords;
  const PrioritizedRecommendationDto({
    this.priority = 0,
    this.title,
    this.description,
    this.keywords = const [],
  });

  factory PrioritizedRecommendationDto.fromJson(Map<String, dynamic> json) =>
      PrioritizedRecommendationDto(
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        description: json['description'] as String?,
        keywords: _stringList(json['keywords']),
      );
}

class FormatCheckDto {
  final String? severity;
  final String? label;
  final String? detail;
  const FormatCheckDto({this.severity, this.label, this.detail});

  factory FormatCheckDto.fromJson(Map<String, dynamic> json) => FormatCheckDto(
        severity: json['severity'] as String?,
        label: json['label'] as String?,
        detail: json['detail'] as String?,
      );
}
