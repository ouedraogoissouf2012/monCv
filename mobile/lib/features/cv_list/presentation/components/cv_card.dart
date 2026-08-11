import 'package:flutter/material.dart';

import '../../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../../services/cv_readiness_service.dart';
import 'cv_card_actions.dart';
import 'cv_card_badges.dart';
import 'cv_card_header.dart';
import 'cv_card_metrics.dart';

/// Carte d'un CV dans la liste (issue #249, D3).
///
/// Orchestrateur mince qui compose des sous-composants SPECIFIQUES (badges,
/// header, metrics, actions) — pas de « GenericCard » sur-parametree (crit.
/// #249). Le score de readiness est calcule une fois et partage aux enfants.
/// Remplace le monolithe cv_card.dart (350 l.).
class CvCard extends StatelessWidget {
  const CvCard({
    super.key,
    required this.cv,
    required this.onTap,
    required this.onEdit,
    required this.onDownloadPdf,
    required this.onDownloadDocx,
    required this.onDelete,
    required this.onDuplicate,
    required this.onShare,
  });

  final Cv cv;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDownloadPdf;
  final VoidCallback onDownloadDocx;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;

  void _onMenu(CvCardMenuAction action) {
    switch (action) {
      case CvCardMenuAction.edit:
        onEdit();
      case CvCardMenuAction.duplicate:
        onDuplicate();
      case CvCardMenuAction.share:
        onShare();
      case CvCardMenuAction.delete:
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readiness = const CvReadinessService().evaluate(cv);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CvCardBadges(cv: cv),
              CvCardHeader(
                  title: cv.titre, readiness: readiness, onAction: _onMenu),
              CvCardMetrics(cv: cv, score: readiness.score),
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              CvCardActions(
                onView: onTap,
                onShare: onShare,
                onDownloadPdf: onDownloadPdf,
                onDownloadDocx: onDownloadDocx,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
