import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/cv/domain/entities/language.dart';
import '../../../../features/cv/domain/entities/skill.dart';
import '../../../../utils/cv_levels.dart';
import '../cv_document_view_model.dart';
import '../theme/cv_document_theme.dart';

/// Liste des competences avec barre de progression et libelle de niveau
/// (issue #243). Extrait de `_skillsBars` ; l'eclatement "Java, Python" ->
/// entrees vient de [CvDocumentViewModel].
class SkillLevelBars extends StatelessWidget {
  const SkillLevelBars({super.key, required this.skills, required this.accent});

  final List<Skill> skills;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final views = CvDocumentViewModel.splitSkills(skills);
    return Column(
      children: views
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(
                    width: 90,
                    child: Text(s.name,
                        style: const TextStyle(
                            fontSize: CvDocumentTheme.sizeBody,
                            fontWeight: CvDocumentTheme.weightEntryTitle)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: skillLevelProgress(s.level),
                        minHeight: 4,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 62,
                    child: Text(localizedSkillLevelLabel(l, s.level),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: CvDocumentTheme.sizeChipLabel,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ))
          .toList(),
    );
  }
}

/// Liste des langues avec barre de progression et niveau CEFR (issue #243).
/// Extrait de `_langBars`.
class LanguageLevelBars extends StatelessWidget {
  const LanguageLevelBars(
      {super.key, required this.languages, required this.accent});

  final List<Language> languages;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: languages
          .map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.langue ?? '',
                            style: const TextStyle(
                                fontSize: CvDocumentTheme.sizeBody,
                                fontWeight: CvDocumentTheme.weightEntryTitle)),
                        Text(localizedLanguageLevelDisplay(l, lang.niveau),
                            style: TextStyle(
                                fontSize: CvDocumentTheme.sizeChipLabel,
                                color: accent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: languageLevelProgress(lang.niveau),
                        minHeight: 4,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
