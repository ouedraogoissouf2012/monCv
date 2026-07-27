import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Couleurs semantiques metier absentes du [ColorScheme] Material, portees par
/// le theme via un [ThemeExtension]. Source unique pour success / warning /
/// info / danger / offline, les scores de qualite et les statuts de
/// candidature (issue #233).
///
/// Les roles fondamentaux (primary, surface, error...) restent dans
/// `Theme.of(context).colorScheme`. Cette extension ne couvre que ce que le
/// ColorScheme ne modelise pas. Chaque teinte possede sa paire `on*` pour
/// garantir un contraste texte/fond conforme WCAG AA (verifie par test).
///
/// Acces : `Theme.of(context).extension<AppColorTokens>()!`.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.danger,
    required this.onDanger,
    required this.offline,
    required this.onOffline,
    required this.scoreGood,
    required this.scoreMedium,
    required this.scorePoor,
    required this.statusDraft,
    required this.statusSent,
    required this.statusInterview,
    required this.statusTechnicalTest,
    required this.statusOffer,
    required this.statusRejected,
    required this.statusArchived,
    required this.onStatus,
  });

  /// Etat de reussite (validation, action confirmee).
  final Color success;
  final Color onSuccess;

  /// Anomalie recuperable, attention requise.
  final Color warning;
  final Color onWarning;

  /// Information neutre non bloquante.
  final Color info;
  final Color onInfo;

  /// Erreur / action destructrice. Distinct de `ColorScheme.error` pour laisser
  /// les bannieres metier diverger du rouge systeme si besoin.
  final Color danger;
  final Color onDanger;

  /// Etat hors-ligne (banniere de perte de connectivite).
  final Color offline;
  final Color onOffline;

  /// Indicateurs de score de qualite du CV (bon / moyen / faible).
  ///
  /// Ces teintes servent a la fois de couleur de remplissage (barre de
  /// progression) et de couleur de texte pose sur la surface du mode (cf.
  /// `widgets/cv_card.dart`). Invariant verrouille par test : chaque score
  /// contraste >= 4.5:1 (WCAG AA) avec `scaffoldBackground` ET `cardColor` du
  /// theme correspondant.
  final Color scoreGood;
  final Color scoreMedium;
  final Color scorePoor;

  /// Statuts du suivi de candidature.
  final Color statusDraft;
  final Color statusSent;
  final Color statusInterview;
  final Color statusTechnicalTest;
  final Color statusOffer;
  final Color statusRejected;
  final Color statusArchived;

  /// Premier plan lisible pose sur n'importe quelle pastille de statut.
  final Color onStatus;

  @override
  AppColorTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? danger,
    Color? onDanger,
    Color? offline,
    Color? onOffline,
    Color? scoreGood,
    Color? scoreMedium,
    Color? scorePoor,
    Color? statusDraft,
    Color? statusSent,
    Color? statusInterview,
    Color? statusTechnicalTest,
    Color? statusOffer,
    Color? statusRejected,
    Color? statusArchived,
    Color? onStatus,
  }) {
    return AppColorTokens(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      offline: offline ?? this.offline,
      onOffline: onOffline ?? this.onOffline,
      scoreGood: scoreGood ?? this.scoreGood,
      scoreMedium: scoreMedium ?? this.scoreMedium,
      scorePoor: scorePoor ?? this.scorePoor,
      statusDraft: statusDraft ?? this.statusDraft,
      statusSent: statusSent ?? this.statusSent,
      statusInterview: statusInterview ?? this.statusInterview,
      statusTechnicalTest: statusTechnicalTest ?? this.statusTechnicalTest,
      statusOffer: statusOffer ?? this.statusOffer,
      statusRejected: statusRejected ?? this.statusRejected,
      statusArchived: statusArchived ?? this.statusArchived,
      onStatus: onStatus ?? this.onStatus,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      onOffline: Color.lerp(onOffline, other.onOffline, t)!,
      scoreGood: Color.lerp(scoreGood, other.scoreGood, t)!,
      scoreMedium: Color.lerp(scoreMedium, other.scoreMedium, t)!,
      scorePoor: Color.lerp(scorePoor, other.scorePoor, t)!,
      statusDraft: Color.lerp(statusDraft, other.statusDraft, t)!,
      statusSent: Color.lerp(statusSent, other.statusSent, t)!,
      statusInterview: Color.lerp(statusInterview, other.statusInterview, t)!,
      statusTechnicalTest:
          Color.lerp(statusTechnicalTest, other.statusTechnicalTest, t)!,
      statusOffer: Color.lerp(statusOffer, other.statusOffer, t)!,
      statusRejected: Color.lerp(statusRejected, other.statusRejected, t)!,
      statusArchived: Color.lerp(statusArchived, other.statusArchived, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }

  /// Palette semantique commune aux themes clairs (Minimal, Vibrant). Les
  /// teintes de base viennent d'[AppColors]; les statuts partagent un premier
  /// plan blanc, dont le contraste est verifie par test.
  static const AppColorTokens light = AppColorTokens(
    success: AppColors.success,
    onSuccess: AppColors.onSuccess,
    warning: AppColors.warning,
    onWarning: AppColors.onWarning,
    info: AppColors.info,
    onInfo: AppColors.onInfo,
    danger: AppColors.error,
    onDanger: AppColors.onError,
    offline: AppColors.neutral600,
    onOffline: AppColors.white,
    scoreGood: AppColors.success,
    scoreMedium: AppColors.warning,
    scorePoor: AppColors.error,
    statusDraft: AppColors.statusDraft,
    statusSent: AppColors.statusSent,
    statusInterview: AppColors.statusInterview,
    statusTechnicalTest: AppColors.warning,
    statusOffer: AppColors.success,
    statusRejected: AppColors.error,
    statusArchived: AppColors.statusArchived,
    onStatus: AppColors.white,
  );

  /// Palette semantique du theme sombre Premium. Les teintes sont eclaircies
  /// pour rester lisibles sur fond sombre; les premiers plans passent en fonce.
  static const AppColorTokens dark = AppColorTokens(
    success: AppColors.green,
    onSuccess: AppColors.neutral950,
    warning: AppColors.amber,
    onWarning: AppColors.neutral950,
    info: AppColors.blueLight,
    onInfo: AppColors.neutral950,
    danger: AppColors.redStrong,
    onDanger: AppColors.neutral950,
    offline: AppColors.neutral350,
    onOffline: AppColors.neutral950,
    scoreGood: AppColors.green,
    scoreMedium: AppColors.amber,
    scorePoor: AppColors.redLight,
    statusDraft: AppColors.neutral350,
    statusSent: AppColors.blueLight,
    statusInterview: AppColors.violetLight,
    statusTechnicalTest: AppColors.amber,
    statusOffer: AppColors.green,
    statusRejected: AppColors.redStrong,
    statusArchived: AppColors.neutral300,
    onStatus: AppColors.neutral950,
  );
}
