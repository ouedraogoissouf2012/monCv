import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import 'form_sheet.dart';

class ExperienceSection extends StatelessWidget {
  final List<Experience> experiences;
  final Function(List<Experience>) onChanged;

  const ExperienceSection({
    super.key,
    required this.experiences,
    required this.onChanged,
  });

  void _add(BuildContext context) =>
      _showSheet(context, null, (e) => onChanged([...experiences, e]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, experiences[i], (e) {
        final list = List<Experience>.from(experiences);
        list[i] = e;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Experience>.from(experiences);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Experience? exp,
    Function(Experience) onSave,
  ) {
    final posteCtrl = TextEditingController(text: exp?.poste);
    final entrepriseCtrl = TextEditingController(text: exp?.entreprise);
    final lieuCtrl = TextEditingController(text: exp?.lieu);
    final descCtrl = TextEditingController(text: exp?.description);
    DateTime? debut = exp?.dateDebut;
    DateTime? fin = exp?.dateFin;
    bool actuel = exp?.actuel ?? false;

    showFormSheet(
      context: context,
      title: exp == null ? 'Ajouter une expérience' : 'Modifier l\'expérience',
      icon: Icons.work_outline_rounded,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: posteCtrl,
            decoration: const InputDecoration(
              labelText: 'Intitulé du poste *',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: entrepriseCtrl,
            decoration: const InputDecoration(
              labelText: 'Entreprise',
              prefixIcon: Icon(Icons.business_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: lieuCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
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
              if (!actuel) ...[
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
            decoration: const InputDecoration(
              labelText: 'Description des responsabilités',
              hintText: 'Décrivez vos missions principales...',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      onSave: () => onSave(Experience(
        id: exp?.id,
        poste: posteCtrl.text,
        entreprise: entrepriseCtrl.text,
        lieu: lieuCtrl.text,
        dateDebut: debut,
        dateFin: fin,
        description: descCtrl.text,
        actuel: actuel,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (experiences.isEmpty)
          const SectionEmptyState(
            icon: Icons.work_outline_rounded,
            label: 'Aucune expérience ajoutée',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experiences.length,
            itemBuilder: (ctx, i) {
              final exp = experiences[i];
              return SectionItemTile(
                title: exp.poste?.isNotEmpty == true ? exp.poste! : 'Sans titre',
                subtitle: exp.entreprise ?? '',
                badge: exp.actuel ? 'En poste' : null,
                badgeColor: Colors.green,
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter une expérience',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
