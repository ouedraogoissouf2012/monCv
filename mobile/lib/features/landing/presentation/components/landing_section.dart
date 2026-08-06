import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../landing_metrics.dart';

/// Conteneur pleine largeur d'une section de la landing (issue #251).
///
/// Factorise le motif repete du monolithe : largeur infinie, gouttieres
/// horizontales responsives (larges sur desktop, etroites sur mobile) et padding
/// vertical de section. La couleur de fond est optionnelle.
class LandingSection extends StatelessWidget {
  const LandingSection({
    super.key,
    required this.child,
    this.background,
    this.verticalPadding = LandingMetrics.sectionVerticalPadding,
    this.horizontalPadding,
  });

  final Widget child;
  final Color? background;
  final double verticalPadding;

  /// Padding horizontal fixe. Si `null` (defaut), une gouttiere responsive est
  /// appliquee (large sur desktop, etroite sur mobile). Les sections a largeur
  /// constante (CTA, footer, preuve sociale) fournissent une valeur fixe.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final horizontal = horizontalPadding ??
        (LandingMetrics.isWide(context)
            ? AppSpacing.gutterWide
            : AppSpacing.xxl);
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: verticalPadding,
      ),
      child: child,
    );
  }
}
