import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../components/landing_section.dart';
import '../components/landing_section_header.dart';

/// Section « comment ca marche » (issue #251) : trois etapes numerotees.
/// Extraction verbatim du monolithe.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LandingSection(
      child: Column(children: [
        LandingSectionHeader(title: l.howItWorks),
        const SizedBox(height: 40),
        Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            _Step(number: '1', title: l.fillIn, description: l.fillInDescription),
            _Step(number: '2', title: l.adapt, description: l.adaptDescription),
            _Step(number: '3', title: l.send, description: l.sendDescription),
          ],
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.brandBlue,
          child: Text(number,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            style: const TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text(description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: AppTypography.fontFamilyBody,
                fontSize: 13,
                color: AppColors.neutral450,
                height: 1.5)),
      ]),
    );
  }
}
