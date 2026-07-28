/// Analyse typée de correspondance CV / offre (endpoint `/ai/match-job`).
///
/// Entité de domaine : Dart pur, sans Flutter, HTTP ni JSON.
class JobMatch {
  final int score;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> suggestions;
  final List<MatchCategory> categories;
  final List<PrioritizedRecommendation> prioritizedRecommendations;
  final List<FormatCheck> formatChecks;
  final String? optimizedResume;
  final bool aiGenerated;
  final bool fallback;

  const JobMatch({
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
}

/// Score ATS detaille par categorie.
class MatchCategory {
  final String? key;
  final String? label;
  final int score;
  final String? summary;
  final List<String> evidence;
  const MatchCategory({
    this.key,
    this.label,
    this.score = 0,
    this.summary,
    this.evidence = const [],
  });
}

/// Recommandation priorisee pour ameliorer le match.
class PrioritizedRecommendation {
  final int priority;
  final String? title;
  final String? description;
  final List<String> keywords;
  const PrioritizedRecommendation({
    this.priority = 0,
    this.title,
    this.description,
    this.keywords = const [],
  });
}

/// Verification de forme (structure/lisibilite du CV).
class FormatCheck {
  final String? severity;
  final String? label;
  final String? detail;
  const FormatCheck({this.severity, this.label, this.detail});
}
