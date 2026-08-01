import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/cv_document_view_model.dart';
import '../theme/cv_document_theme.dart';
import 'cv_entry_widgets.dart';
import 'cv_level_bars.dart';
import 'cv_section_header.dart';

/// Corps commun d'un CV : ordre canonique des sections et mises en page a deux
/// colonnes (competences/langues, certifications/projets) — issue #243.
///
/// Extrait de `_bodySections` du monolithe. N'affiche que les sections non
/// vides (via [CvDocumentViewModel]). Reutilise par les templates qui partagent
/// ce corps ; un template au rendu different fournit le sien.
class CvBodySections extends StatelessWidget {
  const CvBodySections({
    super.key,
    required this.document,
    required this.accent,
  });

  final CvDocumentViewModel document;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cv = document.cv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (document.hasSummary) ...[
          CvSectionHeader(title: l.profile, accent: accent),
          Text(cv.personalInfo!.resumeProfessionnel!,
              style: const TextStyle(
                  fontSize: CvDocumentTheme.sizeBody,
                  height: CvDocumentTheme.summaryLineHeight,
                  color: CvDocumentTheme.textBody)),
        ],
        if (document.hasSkills || document.hasLanguages)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (document.hasSkills)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CvSectionHeader(title: l.skills, accent: accent),
                      SkillLevelBars(skills: cv.skills, accent: accent),
                    ],
                  ),
                ),
              if (document.hasSkills && document.hasLanguages)
                const SizedBox(width: 20),
              if (document.hasLanguages)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CvSectionHeader(title: l.languages, accent: accent),
                      LanguageLevelBars(
                          languages: cv.languages, accent: accent),
                    ],
                  ),
                ),
            ],
          ),
        if (document.hasExperiences) ...[
          CvSectionHeader(title: l.experiences, accent: accent),
          ...cv.experiences
              .map((e) => ExperienceEntry(experience: e, accent: accent)),
        ],
        if (document.hasEducations) ...[
          CvSectionHeader(title: l.education, accent: accent),
          ...cv.educations
              .map((e) => EducationEntry(education: e, accent: accent)),
        ],
        if (document.hasCertifications || document.hasProjects)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (document.hasCertifications)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CvSectionHeader(title: l.certifications, accent: accent),
                      ...cv.certifications.map(
                          (c) => CertificationEntry(certification: c, accent: accent)),
                    ],
                  ),
                ),
              if (document.hasCertifications && document.hasProjects)
                const SizedBox(width: 20),
              if (document.hasProjects)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CvSectionHeader(title: l.projects, accent: accent),
                      ...cv.projects
                          .map((p) => ProjectEntry(project: p, accent: accent)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
