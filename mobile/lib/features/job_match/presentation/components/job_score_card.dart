import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Seuils d'affichage du score de correspondance ATS (issue #245).
/// Regroupes ici pour eviter la duplication (score card + category card).
abstract final class JobMatchScoreThresholds {
  /// >= [good] : bonne correspondance (vert).
  static const int good = 70;

  /// >= [average] : correspondance moyenne (orange) ; en dessous : faible.
  static const int average = 40;

  /// Couleur associee a un score.
  static Color colorFor(int score) => score >= good
      ? AppColors.success
      : score >= average
          ? AppColors.warning
          : AppColors.error;
}

/// Carte principale du score de correspondance (jauge circulaire + libelle) —
/// issue #245. Extraite de `_ScoreCard`.
class JobScoreCard extends StatelessWidget {
  const JobScoreCard({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = JobMatchScoreThresholds.colorFor(score);
    final label = score >= JobMatchScoreThresholds.good
        ? l.goodMatch
        : score >= JobMatchScoreThresholds.average
            ? l.averageMatch
            : l.lowMatch;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('$score%',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(l.jobMatchScore,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Intitule de section du rapport de correspondance. Extrait de `_SectionTitle`.
class JobSectionTitle extends StatelessWidget {
  const JobSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}
