import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/cv.dart';
import '../../../../utils/cv_levels.dart';
import '../../domain/cv_document_view_model.dart';
import '../sections/cv_entry_widgets.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « ATS-Safe » : une seule colonne, texte pur, sans element graphique,
/// 100% compatible avec les robots de tri (issue #243). Extrait a l'identique
/// de `_AtsTemplate`.
///
/// N'utilise volontairement PAS les sections riches (barres de niveau) : les
/// competences/langues sont rendues en ligne "nom (niveau)" pour rester
/// parsables. En-tetes de section propres (`_atsSection`).
class AtsPreviewTemplate extends CvPreviewTemplate {
  const AtsPreviewTemplate();

  static const Color _black = CvDocumentTheme.textStrong;
  static const Color _grey = CvDocumentTheme.textMuted;

  @override
  String get id => 'ats';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final l = AppLocalizations.of(context)!;
    final cv = document.cv;
    final info = cv.personalInfo;
    final skills = document.skills;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true)
        '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
    ].join('  |  ');

    return DefaultTextStyle(
      style: CvDocumentTheme.font(cv.style.fontFamily,
          const TextStyle(fontSize: CvDocumentTheme.sizeTitle, color: _black)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _black)),
            if (info?.titrePoste?.isNotEmpty == true)
              Text(info!.titrePoste!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _grey)),
            const SizedBox(height: 6),
            Text(contact,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeBody, color: _grey)),
            if (document.hasSummary) ...[
              _atsSection(l.profile),
              Text(info!.resumeProfessionnel!,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeTitle,
                      height: CvDocumentTheme.summaryLineHeight,
                      color: _black)),
            ],
            if (skills.isNotEmpty) ...[
              _atsSection(l.skills),
              Text(
                skills
                    .map((s) =>
                        '${s.name} (${localizedSkillLevelLabel(l, s.level)})')
                    .join('  -  '),
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeTitle, color: _black),
              ),
            ],
            if (document.hasLanguages) ...[
              _atsSection(l.languages),
              Text(
                cv.languages
                    .map((lang) =>
                        '${lang.langue ?? ''} (${localizedLanguageLevelDisplay(l, lang.niveau)})')
                    .join('  -  '),
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeTitle, color: _black),
              ),
            ],
            if (document.hasExperiences) ...[
              _atsSection(l.experiences),
              ...cv.experiences.map((e) => _AtsExperience(experience: e)),
            ],
            if (document.hasEducations) ...[
              _atsSection(l.education),
              ...cv.educations.map((e) => _AtsEducation(education: e)),
            ],
            if (document.hasCertifications) ...[
              _atsSection(l.certifications),
              ...cv.certifications.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      Expanded(
                        child: Text(c.nom ?? '',
                            style: const TextStyle(
                                fontSize: CvDocumentTheme.sizeTitle,
                                color: _black)),
                      ),
                      Text(CvDocumentViewModel.formatMonthYear(c.dateObtention),
                          style: const TextStyle(
                              fontSize: CvDocumentTheme.sizeBody, color: _grey)),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// En-tete de section ATS : titre en capitales + trait noir plein.
  static Widget _atsSection(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeTitle,
                    fontWeight: FontWeight.w800,
                    color: _black,
                    letterSpacing: 1)),
            const SizedBox(height: 2),
            Container(height: 1, color: _black),
          ],
        ),
      );
}

/// Bloc experience ATS (poste + date, entreprise/lieu, description a puces).
class _AtsExperience extends StatelessWidget {
  const _AtsExperience({required this.experience});
  final Experience experience;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = experience;
    final date = CvDocumentViewModel.formatDateRange(e.dateDebut, e.dateFin,
        ongoingLabel: l.inProgress, actuel: e.actuel);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(e.poste ?? '',
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeName,
                      fontWeight: FontWeight.w700,
                      color: CvDocumentTheme.textStrong)),
            ),
            if (date.isNotEmpty)
              Text(date,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeBody,
                      color: CvDocumentTheme.textMuted)),
          ]),
          Text(
              [e.entreprise, e.lieu]
                  .where((s) => s?.isNotEmpty == true)
                  .join(', '),
              style: const TextStyle(
                  fontSize: CvDocumentTheme.sizeBody,
                  color: CvDocumentTheme.textMuted)),
          if (e.description?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            ...buildDescriptionLines(e.description!, CvDocumentTheme.textStrong),
          ],
        ],
      ),
    );
  }
}

/// Bloc formation ATS (diplome + date, etablissement).
class _AtsEducation extends StatelessWidget {
  const _AtsEducation({required this.education});
  final Education education;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = education;
    final date = CvDocumentViewModel.formatDateRange(e.dateDebut, e.dateFin,
        ongoingLabel: l.inProgress);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(e.diplome ?? '',
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeName,
                      fontWeight: FontWeight.w700,
                      color: CvDocumentTheme.textStrong)),
            ),
            if (date.isNotEmpty)
              Text(date,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeBody,
                      color: CvDocumentTheme.textMuted)),
          ]),
          if (e.etablissement?.isNotEmpty == true)
            Text(e.etablissement!,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeBody,
                    color: CvDocumentTheme.textMuted)),
        ],
      ),
    );
  }
}
