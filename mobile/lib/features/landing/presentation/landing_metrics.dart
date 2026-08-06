import 'package:flutter/widgets.dart';

/// Metriques de mise en page de la landing marketing (issue #251).
///
/// Valeurs specifiques a la landing, nommees pour supprimer les magic numbers
/// inline du monolithe tout en preservant le rendu exact (refactor structurel,
/// pas de redesign — cf. non-regression #251).
///
/// Le breakpoint [wide] (800) ne correspond a aucun token global
/// `AppBreakpoints` (600 / 1024) : le conserver evite un changement visuel entre
/// 600 et 1024 px. Il reste donc volontairement feature-scoped plutot que de
/// polluer les tokens partages.
abstract final class LandingMetrics {
  const LandingMetrics._();

  /// Seuil « large » de la landing (mobile empile vs desktop cote a cote).
  static const double wide = 800;

  /// Padding vertical standard d'une section marketing.
  static const double sectionVerticalPadding = 64;

  /// Vrai si la largeur courante depasse le seuil [wide].
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;
}
