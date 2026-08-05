import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/job_application_status.dart';
import 'application_status_presentation.dart';

/// Puce coloree affichant le statut d'une candidature (issue #246, A6a).
/// Reutilise le mapping centralise [ApplicationStatusPresentation].
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge(this.status, {super.key});

  final JobApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = ApplicationStatusPresentation.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ApplicationStatusPresentation.icon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            ApplicationStatusPresentation.label(l, status),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
