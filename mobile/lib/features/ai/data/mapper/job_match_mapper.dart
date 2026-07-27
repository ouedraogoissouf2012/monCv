import '../../domain/entities/job_match.dart';
import '../dto/job_match_dto.dart';

/// Convertit le DTO `JobMatchResponse` en entité de domaine [JobMatch].
abstract final class JobMatchMapper {
  static JobMatch fromDto(JobMatchDto dto) => JobMatch(
        score: dto.score,
        matchedKeywords: dto.matchedKeywords,
        missingKeywords: dto.missingKeywords,
        suggestions: dto.suggestions,
        categories: dto.categories
            .map((c) => MatchCategory(
                  key: c.key,
                  label: c.label,
                  score: c.score,
                  summary: c.summary,
                  evidence: c.evidence,
                ))
            .toList(growable: false),
        prioritizedRecommendations: dto.prioritizedRecommendations
            .map((r) => PrioritizedRecommendation(
                  priority: r.priority,
                  title: r.title,
                  description: r.description,
                  keywords: r.keywords,
                ))
            .toList(growable: false),
        formatChecks: dto.formatChecks
            .map((f) => FormatCheck(
                  severity: f.severity,
                  label: f.label,
                  detail: f.detail,
                ))
            .toList(growable: false),
        optimizedResume: dto.optimizedResume,
        aiGenerated: dto.aiGenerated,
        fallback: dto.fallback,
      );
}
