import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/cv_readiness_service.dart';
import '../../../../widgets/cv_readiness_badge.dart';
import 'cv_score_presentation.dart';

/// Actions du menu contextuel d'une carte CV.
enum CvCardMenuAction { edit, duplicate, share, delete }

/// En-tete d'une carte CV (issue #249, D3) : titre + badge de readiness + menu
/// d'actions. Extrait du monolithe (cv_card.dart:137-215).
class CvCardHeader extends StatelessWidget {
  const CvCardHeader({
    super.key,
    required this.title,
    required this.readiness,
    required this.onAction,
  });

  final String title;
  final CvReadinessReport readiness;
  final ValueChanged<CvCardMenuAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 4),
        CvReadinessBadge(
            report: readiness,
            color: CvScorePresentation.color(readiness.score)),
        PopupMenuButton<CvCardMenuAction>(
          icon: Icon(Icons.more_vert,
              size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          padding: EdgeInsets.zero,
          onSelected: onAction,
          itemBuilder: (_) => [
            _item(CvCardMenuAction.edit, Icons.edit_outlined, l.edit),
            _item(CvCardMenuAction.duplicate, Icons.copy_outlined, l.duplicate),
            _item(CvCardMenuAction.share, Icons.share_outlined, l.share),
            const PopupMenuDivider(),
            _item(CvCardMenuAction.delete, Icons.delete_outline, l.delete,
                color: colorScheme.error),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<CvCardMenuAction> _item(
          CvCardMenuAction value, IconData icon, String label, {Color? color}) =>
      PopupMenuItem(
        value: value,
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: color == null ? null : TextStyle(color: color)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      );
}
