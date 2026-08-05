import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/job_application.dart';
import 'application_status_badge.dart';
import 'application_status_presentation.dart';

/// Ligne d'une candidature dans la liste (issue #246, A6a).
///
/// Extraite du monolithe. Deux corrections vs l'original :
/// - couleur via le mapping centralise [ApplicationStatusPresentation] ;
/// - l'ouverture d'URL est DELEGUEE a [onOpenUrl] (le parent passe par
///   ExternalLinkLauncher A3), au lieu d'un `launchUrl` brut non valide.
///
/// [isDue] est calcule par l'appelant avec l'horloge injectee (le domaine
/// n'expose plus de getter lie a `DateTime.now()`).
class ApplicationListRow extends StatelessWidget {
  const ApplicationListRow({
    super.key,
    required this.value,
    required this.isDue,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenUrl,
  });

  final JobApplication value;
  final bool isDue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final color = ApplicationStatusPresentation.color(value.status);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business_center_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(value.position,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      ApplicationStatusBadge(value.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(value.company,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  if (value.cvTitle != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.description_outlined, size: 15),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                            '${value.cvVariant ? '${l.variant} · ' : ''}${value.cvTitle}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ]),
                  ],
                  if (value.nextFollowUp != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(
                          isDue
                              ? Icons.notification_important
                              : Icons.schedule,
                          size: 16,
                          color: isDue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        '${l.nextFollowUp}: ${dateFormat.format(value.nextFollowUp!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDue ? colorScheme.error : null,
                              fontWeight: isDue ? FontWeight.w600 : null,
                            ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                  case 'open':
                    onOpenUrl();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                if (value.offerUrl != null)
                  PopupMenuItem(value: 'open', child: Text(l.openOffer)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
