import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../components/landing_section.dart';

/// Pied de page de la landing (issue #251) : logotype et mention.
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LandingSection(
      background: AppColors.neutral900,
      horizontalPadding: AppSpacing.xxl,
      verticalPadding: AppSpacing.xxxl,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.description_outlined, size: 18, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text('MonCV',
              style: AppTypography.display(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(l.landingFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }
}
