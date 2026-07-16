import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/cv.dart';
import '../../../services/i_api_client.dart';
import 'experience_section.dart' show showSuggestionsSheet;
import 'form_sheet.dart';

class ProjectsSection extends StatelessWidget {
  final List<Project> projects;
  final Function(List<Project>) onChanged;

  const ProjectsSection({
    super.key,
    required this.projects,
    required this.onChanged,
  });

  void _add(BuildContext context) =>
      _showSheet(context, null, (p) => onChanged([...projects, p]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, projects[i], (p) {
        final list = List<Project>.from(projects);
        list[i] = p;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Project>.from(projects);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Project? proj,
    Function(Project) onSave,
  ) {
    final l = AppLocalizations.of(context)!;
    final nomCtrl = TextEditingController(text: proj?.nom);
    final descCtrl = TextEditingController(text: proj?.description);
    final techCtrl = TextEditingController(text: proj?.technologies);
    final lienCtrl = TextEditingController(text: proj?.lien);
    DateTime? dateDebut = proj?.dateDebut;
    DateTime? dateFin = proj?.dateFin;
    bool isLoadingAi = false;

    showFormSheet(
      context: context,
      title: proj == null ? l.addProject : l.editProject,
      icon: Icons.rocket_launch_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: InputDecoration(
              labelText: l.projectNameRequired,
              prefixIcon: const Icon(Icons.rocket_launch_outlined, size: 20),
            ),
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
                child: SectionDateButton(
                  label: l.start,
                  date: dateDebut,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: dateDebut ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => dateDebut = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionDateButton(
                  label: l.end,
                  date: dateFin,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: dateFin ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => dateFin = d);
                  },
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
          AiSuggestButton(
            isLoading: isLoadingAi,
            onPressed: () async {
              setState(() => isLoadingAi = true);
              try {
                final suggestions =
                    await ctx.read<IApiClient>().getAiSuggestions(
                          poste: nomCtrl.text,
                          entreprise:
                              techCtrl.text.isNotEmpty ? techCtrl.text : null,
                          description: descCtrl.text,
                        );
                if (!ctx.mounted) return;
                await showSuggestionsSheet(ctx, suggestions, descCtrl);
              } catch (_) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(l.suggestionsGenerationFailed),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                if (ctx.mounted) setState(() => isLoadingAi = false);
              }
            },
          ),
        ],
      ),
      onSave: () => onSave(Project(
        id: proj?.id,
        nom: nomCtrl.text.isNotEmpty ? nomCtrl.text : null,
        description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
        technologies: techCtrl.text.isNotEmpty ? techCtrl.text : null,
        lien: lienCtrl.text.isNotEmpty ? lienCtrl.text : null,
        dateDebut: dateDebut,
        dateFin: dateFin,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (projects.isEmpty)
          SectionEmptyState(
            icon: Icons.rocket_launch_outlined,
            label: l.noneProject,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (ctx, i) {
              final proj = projects[i];
              return SectionItemTile(
                title: proj.nom?.isNotEmpty == true ? proj.nom! : l.projects,
                subtitle: proj.technologies ?? proj.lien ?? '',
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: l.addProject,
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
