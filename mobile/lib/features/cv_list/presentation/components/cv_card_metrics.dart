import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/cv.dart';
import '../../../../utils/app_colors.dart';
import '../../../../widgets/stats_badge.dart';
import 'cv_score_presentation.dart';

/// Zone de metriques d'une carte CV (issue #249, D3) : date + nombre de
/// variantes, barre de progression du score, et compteurs de sections.
/// Extraite du monolithe (cv_card.dart:217-298). L'horloge est injectee pour
/// un formatage de date deterministe et testable.
class CvCardMetrics extends StatelessWidget {
  const CvCardMetrics({
    super.key,
    required this.cv,
    required this.score,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Cv cv;

  /// Score de readiness (calcule une fois par la carte parente).
  final int score;
  final DateTime Function() _clock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = CvScorePresentation.color(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_formatDate(cv.updatedAt ?? cv.createdAt, l),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5))),
            if ((cv.variantCount ?? 0) > 0) ...[
              const SizedBox(width: 8),
              Text(l.nVariants(cv.variantCount!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 5,
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(CvScorePresentation.label(score, l),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scoreColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
                child: StatsBadge(
                    count: cv.experiences.length,
                    label: l.experiences,
                    color: colorScheme.primary)),
            Expanded(
                child: StatsBadge(
                    count: cv.skills.length,
                    label: l.skills,
                    color: colorScheme.secondary)),
            Expanded(
                child: StatsBadge(
                    count: cv.educations.length,
                    label: l.education,
                    color: AppColors.success)),
            if (cv.shareToken != null)
              StatsBadge(
                  count: cv.viewCount,
                  label: l.views,
                  color: AppColors.indigo),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime? date, AppLocalizations l) {
    if (date == null) return '';
    final diff = _clock().difference(date);
    if (diff.inDays == 0) return l.today;
    if (diff.inDays == 1) return l.yesterday;
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
