import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/cv_readiness_service.dart';

class CvReadinessBadge extends StatelessWidget {
  final CvReadinessReport report;
  final Color color;

  const CvReadinessBadge({
    super.key,
    required this.report,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Tooltip(
      message: report.issues.isEmpty
          ? l.atsNoFormatRisk
          : report.issues.map((issue) => '• ${issue.message}').join('\n'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${report.score}% ATS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
