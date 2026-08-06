import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../landing_sample_cv.dart';

/// Apercu decoratif d'un CV pour la landing (issue #251).
///
/// Mock marketing stylise (pas un rendu fidele de `CvPreview`) pilote par la
/// fixture [LandingSampleCv] et les libelles ARB `sample*`. Aucune regle de
/// `CvPreview` n'est dupliquee ici.
class LandingCvMock extends StatelessWidget {
  const LandingCvMock({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.lg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header(l),
        _body(l),
      ]),
    );
  }

  Widget _header(AppLocalizations l) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: const BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        child: Column(children: [
          Text(l.sampleCandidateName,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(l.sampleCandidateRole,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 12,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.sampleCandidateContact,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 9,
                  color: Colors.white60)),
        ]),
      );

  Widget _body(AppLocalizations l) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel(l.sampleProfile),
          Text(l.sampleProfileText,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 10,
                  color: AppColors.neutral700,
                  height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(l.sampleSkills),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final skill in LandingSampleCv.skills)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(skill,
                      style: const TextStyle(
                          fontFamily: AppTypography.fontFamilyBody,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(l.sampleExperiences),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l.sampleCandidatePosition,
                style: const TextStyle(
                    fontFamily: AppTypography.fontFamilyBody,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const Text(LandingSampleCv.experiencePeriod,
                style: TextStyle(
                    fontFamily: AppTypography.fontFamilyBody,
                    fontSize: 9,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600)),
          ]),
          Text(l.sampleCandidateCompany,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 9,
                  color: AppColors.neutral450)),
        ]),
      );

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(1.5))),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontFamily: AppTypography.fontFamilyBody,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                  letterSpacing: 1)),
        ]),
      );
}
