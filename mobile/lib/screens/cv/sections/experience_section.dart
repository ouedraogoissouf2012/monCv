import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/result.dart';
import '../../../features/ai/application/suggest_bullets_usecase.dart';
import '../../../features/cv/presentation/section_editor/ai_suggestions_sheet.dart';
import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../features/cv/presentation/section_editor/section_form_fields.dart';
import '../../../features/cv/presentation/section_editor/section_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/domain/entities/experience.dart';

class ExperienceSection extends StatelessWidget {
  final List<Experience> experiences;
  final Function(List<Experience>) onChanged;

  /// Use case de suggestions IA (issue #332). Injectable pour les tests ;
  /// par defaut resolu via le service locator, jamais le transport direct.
  final SuggestBulletsUseCase? suggestBullets;

  const ExperienceSection({
    super.key,
    required this.experiences,
    required this.onChanged,
    this.suggestBullets,
  });

  /// Ouvre l'editeur d'experience et retourne la valeur saisie (ou `null` si
  /// annule / invalide). Ne mute jamais la liste parent.
  Future<Experience?> _editSheet(BuildContext context, Experience? exp) {
    final l = AppLocalizations.of(context)!;
    final posteCtrl = TextEditingController(text: exp?.poste);
    final entrepriseCtrl = TextEditingController(text: exp?.entreprise);
    final lieuCtrl = TextEditingController(text: exp?.lieu);
    final descCtrl = TextEditingController(text: exp?.description);
    DateTime? debut = exp?.dateDebut;
    DateTime? fin = exp?.dateFin;
    bool actuel = exp?.actuel ?? false;
    bool isLoadingAi = false;

    return showSectionEditor<Experience>(
      context: context,
      title: exp == null ? l.addExperience : l.editExperience,
      icon: Icons.work_outline_rounded,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: posteCtrl,
            decoration: InputDecoration(
              labelText: l.jobTitleRequired,
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: entrepriseCtrl,
            decoration: InputDecoration(
              labelText: l.companyRequired,
              prefixIcon: const Icon(Icons.business_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: lieuCtrl,
            decoration: InputDecoration(
              labelText: l.location,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          SectionCurrentSwitch(
            value: actuel,
            onChanged: (v) => setState(() {
              actuel = v;
              if (actuel) fin = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SectionDateButton(
                  label: l.startRequired,
                  date: debut,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: debut ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => debut = d);
                  },
                ),
              ),
              if (!actuel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SectionDateButton(
                    label: l.end,
                    date: fin,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: fin ?? DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => fin = d);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descCtrl,
            decoration: InputDecoration(
              labelText: l.responsibilitiesDescription,
              hintText: l.responsibilitiesHint,
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 6),
          AiSuggestButton(
            isLoading: isLoadingAi,
            onPressed: () async {
              setState(() => isLoadingAi = true);
              final suggest = suggestBullets ?? sl<SuggestBulletsUseCase>();
              final result = await suggest(SuggestBulletsParams(
                poste: posteCtrl.text,
                entreprise: entrepriseCtrl.text,
                description: descCtrl.text,
              ));
              if (!ctx.mounted) return;
              switch (result) {
                case Success(:final data):
                  await showSuggestionsSheet(ctx, data, descCtrl);
                case Failure():
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(l.aiSuggestionsUnavailable),
                      backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(label: l.close, onPressed: () {}),
                    ),
                  );
              }
              if (ctx.mounted) setState(() => isLoadingAi = false);
            },
          ),
        ],
      ),
      buildResult: () => Experience(
        id: exp?.id,
        poste: posteCtrl.text.trim(),
        entreprise: entrepriseCtrl.text.trim(),
        lieu: lieuCtrl.text,
        dateDebut: debut,
        dateFin: actuel ? null : fin,
        description: descCtrl.text,
        actuel: actuel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Experience>(
      items: experiences,
      onChanged: onChanged,
      reorderable: true,
      keyOf: (exp, index) => ValueKey('exp-${exp.id ?? index}'),
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addExperience,
      emptyIcon: Icons.work_outline_rounded,
      emptyLabel: l.noneExperience,
      itemBuilder: (ctx, exp, index,
              {required onEditItem, required onDeleteItem}) =>
          SectionItemTile(
        title: exp.poste?.isNotEmpty == true ? exp.poste! : l.untitled,
        subtitle: exp.entreprise ?? '',
        badge: exp.actuel ? l.currentPosition : null,
        badgeColor: Colors.green,
        onEdit: onEditItem,
        onDelete: onDeleteItem,
      ),
    );
  }
}
