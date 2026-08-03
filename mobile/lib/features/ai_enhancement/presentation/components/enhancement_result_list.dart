import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/enhancement_change.dart';
import 'before_after_row.dart';

/// Liste des changements proposes par l'IA, groupes par section avec un couple
/// avant/apres (issue #244).
///
/// Traduit les [EnhancementField] typés (produits par le use case de diff, qui
/// reste pur) en libelles localises — c'est ici, et seulement ici, que la
/// correspondance champ -> texte affiche est faite.
class EnhancementResultList extends StatelessWidget {
  const EnhancementResultList({super.key, required this.changes});

  final List<EnhancementChange> changes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in changes) ...[
          _label(context, _sectionLabel(l, change)),
          BeforeAfterRow(before: change.before, after: change.after),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  /// Libelle localise d'un champ, avec le numero d'element pour les sections en
  /// liste (ex. "Experiences 2 - Description"). Reproduit la nomenclature du
  /// monolithe.
  static String _sectionLabel(AppLocalizations l, EnhancementChange c) {
    final n = c.index + 1;
    return switch (c.field) {
      EnhancementField.jobTitle => l.jobTitle,
      EnhancementField.professionalSummary => l.professionalSummary,
      EnhancementField.experiencePoste =>
        '${l.experiences} $n - ${l.jobTitle}',
      EnhancementField.experienceDescription =>
        '${l.experiences} $n - ${l.description}',
      EnhancementField.educationEtablissement =>
        '${l.education} $n - ${l.establishment}',
      EnhancementField.educationDiplome =>
        '${l.education} $n - ${l.degree}',
      EnhancementField.educationDomaine =>
        '${l.education} $n - ${l.fieldOfStudy}',
      EnhancementField.educationDescription =>
        '${l.education} $n - ${l.description}',
      EnhancementField.skill => '${l.skills} $n',
      EnhancementField.language => '${l.languages} $n',
      EnhancementField.certificationNom => '${l.certifications} $n',
      EnhancementField.certificationOrganisme =>
        '${l.certifications} $n - ${l.organization}',
      EnhancementField.projectNom => '${l.projects} $n - ${l.name}',
      EnhancementField.projectTechnologies =>
        '${l.projects} $n - ${l.technologies}',
      EnhancementField.projectDescription =>
        '${l.projects} $n - ${l.description}',
    };
  }
}
