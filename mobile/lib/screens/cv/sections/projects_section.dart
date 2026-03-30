import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../services/api_service.dart';
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
    final nomCtrl = TextEditingController(text: proj?.nom);
    final descCtrl = TextEditingController(text: proj?.description);
    final techCtrl = TextEditingController(text: proj?.technologies);
    final lienCtrl = TextEditingController(text: proj?.lien);
    DateTime? dateDebut = proj?.dateDebut;
    DateTime? dateFin = proj?.dateFin;
    bool isLoadingAi = false;

    showFormSheet(
      context: context,
      title: proj == null ? 'Ajouter un projet' : 'Modifier le projet',
      icon: Icons.rocket_launch_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom du projet *',
              prefixIcon: Icon(Icons.rocket_launch_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: techCtrl,
            decoration: const InputDecoration(
              labelText: 'Technologies utilisées',
              prefixIcon: Icon(Icons.code_rounded, size: 20),
              hintText: 'Ex : Flutter, Dart, Firebase',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: lienCtrl,
            decoration: const InputDecoration(
              labelText: 'Lien du projet',
              prefixIcon: Icon(Icons.link_rounded, size: 20),
              hintText: 'https://github.com/...',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SectionDateButton(
                  label: 'Début',
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
                  label: 'Fin',
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
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez le projet, votre rôle...',
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
                final suggestions = await ApiService().getAiSuggestions(
                  poste: nomCtrl.text,
                  entreprise: techCtrl.text.isNotEmpty ? techCtrl.text : null,
                );
                if (!ctx.mounted) return;
                await showSuggestionsSheet(ctx, suggestions, descCtrl);
              } catch (_) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible de générer des suggestions'),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (projects.isEmpty)
          const SectionEmptyState(
            icon: Icons.rocket_launch_outlined,
            label: 'Aucun projet ajouté',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (ctx, i) {
              final proj = projects[i];
              return SectionItemTile(
                title: proj.nom?.isNotEmpty == true ? proj.nom! : 'Projet',
                subtitle: proj.technologies ?? proj.lien ?? '',
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter un projet',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
