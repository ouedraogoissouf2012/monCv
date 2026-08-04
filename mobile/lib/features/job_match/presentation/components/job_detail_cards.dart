import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../ai/domain/entities/job_match.dart';
import 'job_score_card.dart';

/// Carte d'une categorie evaluee (label, score, resume, jusqu'a 2 preuves) —
/// issue #245. Extraite de `_CategoryCard`, typee sur [MatchCategory].
class JobCategoryCard extends StatelessWidget {
  const JobCategoryCard({super.key, required this.category});

  final MatchCategory category;

  static const int _maxEvidence = 2;

  @override
  Widget build(BuildContext context) {
    final evidence = category.evidence
        .where((e) => e.isNotEmpty)
        .take(_maxEvidence)
        .toList();
    final color = JobMatchScoreThresholds.colorFor(category.score);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.label ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${category.score}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pas d'Expanded : la carte prend sa hauteur naturelle et reste
          // utilisable hors grille a hauteur contrainte (critere #245 :
          // aucune grille imposee quand le texte deborde).
          Text(category.summary ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72))),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: evidence
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Liste des recommandations priorisees (numero + titre + description +
/// mots-cles) — issue #245. Extraite de `_RecommendationCard`, typee sur
/// [PrioritizedRecommendation].
class JobRecommendationCard extends StatelessWidget {
  const JobRecommendationCard({super.key, required this.recommendations});

  final List<PrioritizedRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: recommendations.map((rec) {
          final keywords = rec.keywords.where((k) => k.isNotEmpty).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${rec.priority}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.title ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(rec.description ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.75))),
                      if (keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: keywords
                              .map((k) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(k,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Liste des controles de format ATS (ou message "aucun risque" si vide) —
/// issue #245. Extraite de `_FormatChecksCard`, typee sur [FormatCheck].
class JobFormatChecksCard extends StatelessWidget {
  const JobFormatChecksCard({super.key, required this.formatChecks});

  final List<FormatCheck> formatChecks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (formatChecks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
        ),
        child: Text(l.atsNoFormatRisk, style: const TextStyle(fontSize: 12)),
      );
    }

    return Column(
      children: formatChecks.map((item) {
        final config = switch (item.severity) {
          'critical' =>
            (color: AppColors.error, icon: Icons.error_outline_rounded),
          'warning' =>
            (color: AppColors.warning, icon: Icons.warning_amber_rounded),
          _ => (color: AppColors.primary, icon: Icons.info_outline_rounded),
        };
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.color.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(config.icon, size: 18, color: config.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: config.color)),
                    const SizedBox(height: 4),
                    Text(item.detail ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
