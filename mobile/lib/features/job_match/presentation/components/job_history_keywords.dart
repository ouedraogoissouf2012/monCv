import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../domain/job_score_snapshot.dart';

/// Historique des scores ATS de la session, avec ecart vs run precedent —
/// issue #245. Extrait de `_HistoryCard`, typé sur [JobScoreSnapshot].
///
/// Le libelle de chaque entree est derive de [JobScoreSnapshot.isRerun] : le
/// domaine reste localise-agnostique, la traduction se fait ici.
class JobHistoryCard extends StatelessWidget {
  const JobHistoryCard({super.key, required this.history});

  final List<JobScoreSnapshot> history;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final item = entry.value;
          // Ecart avec l'entree PRECEDENTE (plus ancienne, situee apres dans la
          // liste ordonnee du plus recent au plus ancien).
          final diff = entry.key == history.length - 1
              ? null
              : item.score - history[entry.key + 1].score;
          final diffColor =
              (diff ?? 0) >= 0 ? AppColors.success : AppColors.error;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.isRerun ? l.atsRerunLabel : l.atsCurrentRun,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(_formatTime(item.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                Text('${item.score}%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                if (diff != null) ...[
                  const SizedBox(width: 8),
                  Text(diff >= 0 ? '+$diff' : '$diff',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: diffColor)),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

/// Section de mots-cles (matches ou manquants) sous forme de puces colorees —
/// issue #245. Extraite de `_KeywordSection`.
class JobKeywordSection extends StatelessWidget {
  const JobKeywordSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keywords
              .map((k) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(k,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
