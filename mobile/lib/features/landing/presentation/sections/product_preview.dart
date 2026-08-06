import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../components/landing_cv_mock.dart';
import '../components/landing_section.dart';
import '../components/landing_section_header.dart';
import '../landing_metrics.dart';

/// Section apercu produit (issue #251) : montre a quoi ressemble un CV genere,
/// via un mock decoratif ([LandingCvMock]) contraint en largeur.
class ProductPreview extends StatelessWidget {
  const ProductPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWide = LandingMetrics.isWide(context);
    return LandingSection(
      background: AppColors.sectionSurface,
      child: Column(children: [
        LandingSectionHeader(title: l.clearCvTitle, subtitle: l.clearCvSubtitle),
        const SizedBox(height: AppSpacing.xxxl),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
          child: const LandingCvMock(),
        ),
      ]),
    );
  }
}
