import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../components/landing_section.dart';
import '../components/landing_section_header.dart';
import '../landing_metrics.dart';

/// Section « tout ce qu'il faut » (issue #251) : grille de cartes de
/// fonctionnalites (4 + 2). Extraction verbatim du monolithe.
class FeatureOverview extends StatelessWidget {
  const FeatureOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWide = LandingMetrics.isWide(context);
    final features = <(IconData, String, String)>[
      (Icons.auto_awesome_rounded, l.aiFeatureTitle, l.aiFeatureDescription),
      (Icons.picture_as_pdf_outlined, l.templatesFeatureTitle,
          l.templatesFeatureDescription),
      (Icons.work_outline_rounded, l.atsFeatureTitle, l.atsFeatureDescription),
      (Icons.description_outlined, l.docxFeatureTitle, l.docxFeatureDescription),
      (Icons.palette_outlined, l.mobileFeatureTitle, l.mobileFeatureDescription),
      (Icons.chat_outlined, l.whatsAppFeatureTitle, l.whatsAppFeatureDescription),
    ];

    Widget row(Iterable<(IconData, String, String)> items) => Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: items
              .map((f) => SizedBox(
                    width: isWide ? 280 : double.infinity,
                    child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3),
                  ))
              .toList(),
        );

    return LandingSection(
      child: Column(children: [
        LandingSectionHeader(title: l.allYouNeed, subtitle: l.allYouNeedSubtitle),
        const SizedBox(height: 40),
        row(features.take(4)),
        const SizedBox(height: AppSpacing.xxl),
        row(features.skip(4)),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.xl,
          border: Border.all(color: AppColors.neutral100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.08),
                borderRadius: AppRadii.lg),
            child: Icon(icon, color: AppColors.brandBlue, size: 24)),
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            style: const TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text(desc,
            style: const TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: 13,
                color: AppColors.neutral450,
                height: 1.5)),
      ]),
    );
  }
}
