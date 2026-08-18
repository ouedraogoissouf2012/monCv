import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/pwa_install.dart';
import '../components/landing_section.dart';
import '../landing_metrics.dart';

/// Section hero de la landing (issue #251) : logotype, titre de marque,
/// sous-titre et actions d'inscription/connexion. Extraite verbatim du
/// monolithe (refactor structurel).
class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWide = LandingMetrics.isWide(context);
    final heroTitle = isWide ? l.landingHeroTitle : l.landingHeroTitleMobile;
    return LandingSection(
      background: AppColors.brandBlue,
      verticalPadding: isWide ? AppSpacing.gutterWide : AppSpacing.huge,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Colors.white, borderRadius: AppRadii.md),
            child: const Icon(Icons.description_outlined,
                size: 22, color: AppColors.brandBlue),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('MonCV',
              style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
        SizedBox(height: isWide ? AppSpacing.huge : AppSpacing.xxxl),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : 320),
          child: Text(
            heroTitle,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: isWide ? 52 : 31,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.16,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 680 : 300),
          child: Text(
            l.landingHeroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: isWide ? 18 : 14,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.45),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        _HeroActions(isWide: isWide),
      ]),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primary = ElevatedButton(
      onPressed: () => context.go('/register'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandBlue,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
      ),
      child: Text(l.createCvFree,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
    final secondary = OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
      ),
      child: Text(l.login),
    );
    final install = !kIsWeb
        ? null
        : OutlinedButton.icon(
            onPressed: () async {
              final installed = await promptPwaInstall();
              if (!context.mounted || installed) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.installAppHelp)),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l.installApp),
          );
    final actions = [
      primary,
      secondary,
      if (install != null) install,
    ];

    if (isWide) {
      return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: actions);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        primary,
        const SizedBox(height: 12),
        secondary,
        if (install != null) ...[
          const SizedBox(height: 12),
          install,
        ],
      ]),
    );
  }
}
