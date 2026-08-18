import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/cv/domain/entities/certification.dart';
import '../../../../features/cv/domain/entities/education.dart';
import '../../../../features/cv/domain/entities/experience.dart';
import '../../../../features/cv/domain/entities/project.dart';
import '../cv_document_view_model.dart';
import '../theme/cv_document_theme.dart';

/// Entree d'experience : poste, dates, entreprise/lieu, description a puces
/// (issue #243). Extrait de `_expEntry` du monolithe.
class ExperienceEntry extends StatelessWidget {
  const ExperienceEntry({
    super.key,
    required this.experience,
    required this.accent,
  });

  final Experience experience;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = experience;
    final date = CvDocumentViewModel.formatDateRange(
      e.dateDebut,
      e.dateFin,
      ongoingLabel: l.inProgress,
      actuel: e.actuel,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(e.poste ?? '',
                    style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeName,
                      fontWeight: FontWeight.w700,
                      color: CvDocumentTheme.textStrong,
                    )),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(date,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: CvDocumentTheme.sizeMeta,
                          color: accent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          if (e.entreprise?.isNotEmpty == true || e.lieu?.isNotEmpty == true)
            Text(
              [e.entreprise, e.lieu]
                  .where((s) => s?.isNotEmpty == true)
                  .join(' - '),
              style: const TextStyle(
                  fontSize: CvDocumentTheme.sizeBody,
                  color: CvDocumentTheme.textMuted),
            ),
          if (e.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            ...buildDescriptionLines(e.description!, accent),
          ],
        ],
      ),
    );
  }
}

/// Rend une description : soit un paragraphe simple, soit des puces si le texte
/// contient plusieurs lignes ou des marqueurs "- "/"* ". Extrait de
/// `_buildDescLines`.
List<Widget> buildDescriptionLines(String description, Color accent) {
  final lines =
      description.split('\n').where((l) => l.trim().isNotEmpty).toList();
  const bodyStyle = TextStyle(
    fontSize: CvDocumentTheme.sizeBody,
    color: CvDocumentTheme.textBody,
    height: CvDocumentTheme.bodyLineHeight,
  );

  if (lines.length <= 1 && !description.contains('- ')) {
    return [Text(description, style: bodyStyle)];
  }
  return lines.map((line) {
    final t = line.trim();
    final isBullet = t.startsWith('- ') || t.startsWith('* ');
    final text = isBullet ? t.substring(2) : t;
    if (!isBullet) return Text(text, style: bodyStyle);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 5, right: 6),
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(child: Text(text, style: bodyStyle)),
        ],
      ),
    );
  }).toList();
}

/// Entree de formation : diplome, dates, etablissement, description
/// (issue #243). Extrait de `_eduEntry`.
class EducationEntry extends StatelessWidget {
  const EducationEntry({
    super.key,
    required this.education,
    required this.accent,
  });

  final Education education;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = education;
    final date = CvDocumentViewModel.formatDateRange(
      e.dateDebut,
      e.dateFin,
      ongoingLabel: l.inProgress,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            if (date.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(date,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: CvDocumentTheme.sizeMeta,
                        color: accent,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          if (e.etablissement?.isNotEmpty == true)
            Text(e.etablissement!,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeBody,
                    color: CvDocumentTheme.textMuted)),
          if (e.description?.isNotEmpty == true)
            Text(e.description!,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeBody,
                    color: CvDocumentTheme.textBody)),
        ],
      ),
    );
  }
}

/// Entree de certification : puce, nom, date d'obtention. Extrait de
/// `_certEntry`.
class CertificationEntry extends StatelessWidget {
  const CertificationEntry({
    super.key,
    required this.certification,
    required this.accent,
  });

  final Certification certification;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2.5)),
        ),
        Expanded(
          child: Text(certification.nom ?? '',
              style: const TextStyle(
                  fontSize: CvDocumentTheme.sizeBody,
                  fontWeight: FontWeight.w600)),
        ),
        Text(CvDocumentViewModel.formatMonthYear(certification.dateObtention),
            style: TextStyle(
                fontSize: CvDocumentTheme.sizeMeta,
                color: accent,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Entree de projet : nom, technologies, description. Extrait de `_projEntry`.
class ProjectEntry extends StatelessWidget {
  const ProjectEntry({
    super.key,
    required this.project,
    required this.accent,
  });

  final Project project;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.nom ?? '',
              style: const TextStyle(
                  fontSize: CvDocumentTheme.sizeTitle,
                  fontWeight: FontWeight.w700)),
          if (p.technologies?.isNotEmpty == true)
            Text(p.technologies!,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeMeta,
                    color: CvDocumentTheme.textMuted)),
          if (p.description?.isNotEmpty == true)
            Text(p.description!,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeBody,
                    color: CvDocumentTheme.textBody)),
        ],
      ),
    );
  }
}
