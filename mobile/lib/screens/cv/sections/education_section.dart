import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import 'form_sheet.dart';

class EducationSection extends StatelessWidget {
  final List<Education> educations;
  final Function(List<Education>) onChanged;

  const EducationSection({
    super.key,
    required this.educations,
    required this.onChanged,
  });

  void _add(BuildContext context) =>
      _showSheet(context, null, (e) => onChanged([...educations, e]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, educations[i], (e) {
        final list = List<Education>.from(educations);
        list[i] = e;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Education>.from(educations);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Education? edu,
    Function(Education) onSave,
  ) {
    final etablissementCtrl =
        TextEditingController(text: edu?.etablissement);
    final diplomeCtrl = TextEditingController(text: edu?.diplome);
    final domaineCtrl = TextEditingController(text: edu?.domaine);
    final descCtrl = TextEditingController(text: edu?.description);
    DateTime? debut = edu?.dateDebut;
    DateTime? fin = edu?.dateFin;

    showFormSheet(
      context: context,
      title: edu == null ? 'Ajouter une formation' : 'Modifier la formation',
      icon: Icons.school_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: etablissementCtrl,
            decoration: const InputDecoration(
              labelText: 'Établissement *',
              prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: diplomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Diplôme / Titre',
              prefixIcon: Icon(Icons.workspace_premium_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: domaineCtrl,
            decoration: const InputDecoration(
              labelText: 'Domaine d\'études',
              prefixIcon: Icon(Icons.menu_book_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SectionDateButton(
                  label: 'Début',
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
              const SizedBox(width: 12),
              Expanded(
                child: SectionDateButton(
                  label: 'Fin',
                  date: fin,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fin ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (d != null) setState(() => fin = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      onSave: () => onSave(Education(
        id: edu?.id,
        etablissement: etablissementCtrl.text,
        diplome: diplomeCtrl.text,
        domaine: domaineCtrl.text,
        dateDebut: debut,
        dateFin: fin,
        description: descCtrl.text,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (educations.isEmpty)
          const SectionEmptyState(
            icon: Icons.school_outlined,
            label: 'Aucune formation ajoutée',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: educations.length,
            itemBuilder: (ctx, i) {
              final edu = educations[i];
              return SectionItemTile(
                title: edu.diplome?.isNotEmpty == true
                    ? edu.diplome!
                    : edu.etablissement ?? 'Sans titre',
                subtitle: edu.etablissement ?? '',
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter une formation',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
