import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../domain/job_application_status.dart';

/// Mapping presentation d'un statut de candidature (issue #246, A6a).
///
/// CENTRALISE et EXHAUSTIF (crit. #246) : libelle localise + couleur (design
/// system #233) + icone. Le domaine reste localise-agnostique ; toute la
/// correspondance visuelle vit ici, au meme endroit.
abstract final class ApplicationStatusPresentation {
  /// Libelle localise du statut.
  static String label(AppLocalizations l, JobApplicationStatus status) =>
      switch (status) {
        JobApplicationStatus.draft => l.applicationDraft,
        JobApplicationStatus.sent => l.applicationSent,
        JobApplicationStatus.interview => l.applicationInterview,
        JobApplicationStatus.technicalTest => l.applicationTechnicalTest,
        JobApplicationStatus.offer => l.applicationOffer,
        JobApplicationStatus.rejected => l.applicationRejected,
        JobApplicationStatus.archived => l.applicationArchived,
      };

  /// Couleur associee (jetons du design system #233).
  static Color color(JobApplicationStatus status) => switch (status) {
        JobApplicationStatus.draft => AppColors.statusDraft,
        JobApplicationStatus.sent => AppColors.statusSent,
        JobApplicationStatus.interview => AppColors.statusInterview,
        JobApplicationStatus.technicalTest => AppColors.statusTechnicalTest,
        JobApplicationStatus.offer => AppColors.statusOffer,
        JobApplicationStatus.rejected => AppColors.statusRejected,
        JobApplicationStatus.archived => AppColors.statusArchived,
      };

  /// Icone associee au statut.
  static IconData icon(JobApplicationStatus status) => switch (status) {
        JobApplicationStatus.draft => Icons.edit_note_rounded,
        JobApplicationStatus.sent => Icons.send_rounded,
        JobApplicationStatus.interview => Icons.record_voice_over_rounded,
        JobApplicationStatus.technicalTest => Icons.quiz_rounded,
        JobApplicationStatus.offer => Icons.emoji_events_rounded,
        JobApplicationStatus.rejected => Icons.cancel_rounded,
        JobApplicationStatus.archived => Icons.archive_rounded,
      };
}
