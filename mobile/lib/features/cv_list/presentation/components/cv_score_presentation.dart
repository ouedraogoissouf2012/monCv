import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cv/domain/policies/cv_validation_thresholds.dart';
import '../../../../utils/app_colors.dart';

/// Mapping presentation du score de readiness d'un CV (issue #249, D3).
///
/// Couleur et libelle derivent des SEUILS de la politique CV (#241,
/// [CvValidationThresholds]) — le monolithe codait 80/50 en dur (cv_card.dart:
/// 41-51).
abstract final class CvScorePresentation {
  static Color color(int score) {
    if (score >= CvValidationThresholds.displayGoodThreshold) {
      return AppColors.success;
    }
    if (score >= CvValidationThresholds.displayMediumThreshold) {
      return AppColors.warning;
    }
    return AppColors.error;
  }

  static String label(int score, AppLocalizations l) {
    if (score >= CvValidationThresholds.displayGoodThreshold) return l.complete;
    if (score >= CvValidationThresholds.displayMediumThreshold) {
      return l.inProgress;
    }
    return l.incomplete;
  }
}
