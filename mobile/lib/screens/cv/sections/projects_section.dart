import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/result.dart';
import '../../../features/ai/application/suggest_bullets_usecase.dart';
import '../../../features/cv/presentation/section_editor/ai_suggestions_sheet.dart';
import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../features/cv/presentation/section_editor/section_form_fields.dart';
import '../../../utils/strict_date_input.dart';
import '../../../widgets/strict_date_field.dart';
import '../../../features/cv/presentation/section_editor/section_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/domain/entities/project.dart';

class ProjectsSection extends StatelessWidget {
  final List<Project> projects;
  final Function(List<Project>) onChanged;

  /// Use case de suggestions IA (issue #332). Injectable pour les tests ;
  /// par defaut resolu via le service locator, jamais le transport direct.
  final SuggestBulletsUseCase? suggestBullets;

  const ProjectsSection({
    super.key,
    required this.projects,
    required this.onChanged,
    this.suggestBullets,
  });

  /// Ouvre l'editeur de projet et retourne la valeur saisie (ou `null` si
  /// annule / invalide). Ne mute jamais la liste parent.
  Future<Project?> _editSheet(BuildContext context, Project? proj) {
    final l = AppLocalizations.of(context)!;
    final nomCtrl = TextEditingController(text: proj?.nom);
    final descCtrl = TextEditingController(text: proj?.description);
    final techCtrl = TextEditingController(text: proj?.technologies);
    final lienCtrl = TextEditingController(text: proj?.lien);
    DateTime? dateDebut = proj?.dateDebut;
    DateTime? dateFin = proj?.dateFin;
    bool isLoadingAi = false;
    bool aiConsent = false;

    return showSectionEditor<Project>(
      context: context,
      title: proj == null ? l.addProject : l.editProject,
      icon: Icons.rocket_launch_outlined,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: InputDecoration(
              labelText: l.projectNameRequired,
              prefixIcon: const Icon(Icons.rocket_launch_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: techCtrl,
            decoration: InputDecoration(
              labelText: l.technologiesUsed,
              prefixIcon: const Icon(Icons.code_rounded, size: 20),
              hintText: l.technologiesExample,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: lienCtrl,
            decoration: InputDecoration(
              labelText: l.projectLink,
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              hintText: 'https://github.com/...',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StrictDateField(
                  label: l.start,
                  date: dateDebut,
                  minYear: StrictDateInput.minYearDefault,
                  maxYear: StrictDateInput.maxCareerYear(),
                  onChanged: (d) => setState(() => dateDebut = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StrictDateField(
                  label: l.end,
                  date: dateFin,
                  minYear: StrictDateInput.minYearDefault,
                  maxYear: StrictDateInput.maxCareerYear(),
                  onChanged: (d) => setState(() => dateFin = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descCtrl,
            decoration: InputDecoration(
              labelText: l.description,
              hintText: l.projectDescriptionHint,
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: aiConsent,
            onChanged: (v) => setState(() => aiConsent = v ?? false),
            title: Text(l.aiConsent, style: const TextStyle(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          AiSuggestButton(
            isLoading: isLoadingAi,
            onPressed: !aiConsent
                ? null
                : () async {
              setState(() => isLoadingAi = true);
              final suggest = suggestBullets ?? sl<SuggestBulletsUseCase>();
              final result = await suggest(SuggestBulletsParams(
                poste: nomCtrl.text,
                entreprise: techCtrl.text.isNotEmpty ? techCtrl.text : null,
                description: descCtrl.text,
                consentAccepted: aiConsent,
              ));
              if (!ctx.mounted) return;
              switch (result) {
                case Success(:final data):
                  await showSuggestionsSheet(ctx, data, descCtrl);
                case Failure():
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(l.suggestionsGenerationFailed),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
              if (ctx.mounted) setState(() => isLoadingAi = false);
            },
          ),
        ],
      ),
      buildResult: () => Project(
        id: proj?.id,
        nom: nomCtrl.text.trim(),
        description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
        technologies: techCtrl.text.isNotEmpty ? techCtrl.text : null,
        lien: lienCtrl.text.isNotEmpty ? lienCtrl.text : null,
        dateDebut: dateDebut,
        dateFin: dateFin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Project>(
      items: projects,
      onChanged: onChanged,
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addProject,
      emptyIcon: Icons.rocket_launch_outlined,
      emptyLabel: l.noneProject,
      itemBuilder: (ctx, proj, index,
              {required onEditItem, required onDeleteItem}) =>
          SectionItemTile(
        title: proj.nom?.isNotEmpty == true ? proj.nom! : l.projects,
        subtitle: proj.technologies ?? proj.lien ?? '',
        onEdit: onEditItem,
        onDelete: onDeleteItem,
      ),
    );
  }
}
