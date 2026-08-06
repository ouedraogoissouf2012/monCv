import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../components/landing_section.dart';
import '../components/landing_section_header.dart';

/// Section d'appel a l'action finale (issue #251) : incite a creer un CV.
/// Fond de marque, largeur horizontale constante.
class LandingCta extends StatelessWidget {
  const LandingCta({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LandingSection(
      background: AppColors.brandBlue,
      horizontalPadding: AppSpacing.xxl,
      child: Column(children: [
        LandingSectionHeader(
          title: l.readyToApply,
          subtitle: l.readyToApplySubtitle,
          onColor: true,
        ),
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: () => context.go('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brandBlue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
          ),
          child: Text(l.startNow,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ]),
    );
  }
}
