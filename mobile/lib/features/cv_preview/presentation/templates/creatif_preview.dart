import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/cv_levels.dart';
import '../../../../widgets/secure_photo.dart';
import '../cv_document_view_model.dart';
import '../sections/cv_entry_widgets.dart';
import '../sections/cv_section_header.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « Creatif » : sidebar coloree (photo, nom, contact, competences,
/// langues, certifications) + colonne principale (resume, experiences,
/// formations, projets) — issue #243. Extrait a l'identique de
/// `_CreatifTemplate` ; ce template a sa PROPRE mise en page bicolonne et ne
/// reutilise donc pas [CvBodySections].
class CreatifPreviewTemplate extends CvPreviewTemplate {
  const CreatifPreviewTemplate();

  static const int _maxSidebarSkills = 10;

  @override
  String get id => 'creatif';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final l = AppLocalizations.of(context)!;
    final cv = document.cv;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final skills = document.skills;

    return DefaultTextStyle(
      style: CvDocumentTheme.font(
        cv.style.fontFamily,
        const TextStyle(
            fontSize: CvDocumentTheme.sizeBody,
            color: CvDocumentTheme.textBody),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 180,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (info?.photoUrl?.isNotEmpty == true) ...[
                    Center(
                      child: ClipOval(
                        child: SecurePhoto(
                          url: info!.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          fallback: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: Icon(Icons.person,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text('${info?.prenom ?? ''}\n${info?.nom ?? ''}'.trim(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2)),
                  if (info?.titrePoste?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Container(height: 0.4, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(info!.titrePoste!,
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 20),
                  _SideLabel(l.information.toUpperCase()),
                  if (info?.email?.isNotEmpty == true) _SideText(info!.email!),
                  if (info?.telephone?.isNotEmpty == true)
                    _SideText(info!.telephone!),
                  if (info?.ville?.isNotEmpty == true) _SideText(info!.ville!),
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SideLabel(l.skills.toUpperCase()),
                    ...skills.take(_maxSidebarSkills).map(
                          (skill) => _SidebarSkill(
                              name: skill.name,
                              level: skill.level,
                              label: localizedSkillLevelLabel(l, skill.level)),
                        ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SideLabel(l.languages.toUpperCase()),
                    ...cv.languages.map((lang) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Flexible : evite tout debordement dans la
                              // sidebar etroite si le nom de langue est long
                              // (overflow verifie, critere #243).
                              Flexible(
                                child: Text(lang.langue ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 8.5, color: Colors.white)),
                              ),
                              const SizedBox(width: 4),
                              Text(localizedLanguageLevelLabel(l, lang.niveau),
                                  style: const TextStyle(
                                      fontSize: 6.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )),
                  ],
                  if (cv.certifications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SideLabel(l.certifications.toUpperCase()),
                    ...cv.certifications.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(c.nom ?? '',
                              style: const TextStyle(
                                  fontSize: 8.5, color: Colors.white)),
                        )),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (document.hasSummary) ...[
                      CvSectionHeader(
                          title: l.professionalSummary, accent: accent),
                      Text(info!.resumeProfessionnel!,
                          style: const TextStyle(
                              fontSize: CvDocumentTheme.sizeBody,
                              height: CvDocumentTheme.bodyLineHeight,
                              color: CvDocumentTheme.textBody)),
                    ],
                    if (document.hasExperiences) ...[
                      CvSectionHeader(title: l.experiences, accent: accent),
                      ...cv.experiences.map(
                          (e) => ExperienceEntry(experience: e, accent: accent)),
                    ],
                    if (document.hasEducations) ...[
                      CvSectionHeader(title: l.education, accent: accent),
                      ...cv.educations.map(
                          (e) => EducationEntry(education: e, accent: accent)),
                    ],
                    if (document.hasProjects) ...[
                      CvSectionHeader(title: l.projects, accent: accent),
                      ...cv.projects
                          .map((p) => ProjectEntry(project: p, accent: accent)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Intitule de rubrique dans la sidebar (blanc, filet fin).
class _SideLabel extends StatelessWidget {
  const _SideLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2)),
            const SizedBox(height: 3),
            Container(height: 0.4, color: Colors.white),
          ],
        ),
      );
}

/// Ligne de texte simple dans la sidebar.
class _SideText extends StatelessWidget {
  const _SideText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(text,
            style: const TextStyle(fontSize: 8.5, color: Colors.white)),
      );
}

/// Competence de la sidebar : nom + libelle + 5 segments de niveau.
class _SidebarSkill extends StatelessWidget {
  const _SidebarSkill(
      {required this.name, required this.level, required this.label});
  final String name;
  final int level;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 8.5, color: Colors.white))),
                Text(label,
                    style: const TextStyle(
                        fontSize: 6.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: List.generate(
                5,
                (i) => Container(
                  width: 8,
                  height: 3.5,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: i < level.clamp(1, 5)
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
