import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Bandeau de preuve sociale (issue #251) : statistiques cles sous forme de
/// puces centrees. Bande blanche a largeur constante (extraction verbatim).
class SocialProof extends StatelessWidget {
  const SocialProof({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 16,
        children: [
          SizedBox(
              width: 86, child: _StatChip(value: 'FR/EN', label: l.bilingual)),
          SizedBox(width: 72, child: _StatChip(value: '6', label: l.templates)),
          SizedBox(
              width: 86, child: _StatChip(value: 'ATS', label: l.compatible)),
          SizedBox(
              width: 92, child: _StatChip(value: 'WhatsApp', label: l.share)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontFamily: AppTypography.fontFamilyBody,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.brandBlue)),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: AppTypography.fontFamilyBody,
            fontSize: 12,
            color: AppColors.neutral450),
      ),
    ]);
  }
}
