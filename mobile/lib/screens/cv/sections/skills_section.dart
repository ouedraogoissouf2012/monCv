import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import 'form_sheet.dart';

class SkillsSection extends StatelessWidget {
  final List<Skill> skills;
  final Function(List<Skill>) onChanged;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  void _add(BuildContext context) =>
      _showSheet(context, null, (s) => onChanged([...skills, s]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, skills[i], (s) {
        final list = List<Skill>.from(skills);
        list[i] = s;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Skill>.from(skills);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Skill? skill,
    Function(Skill) onSave,
  ) {
    final nomCtrl = TextEditingController(text: skill?.nom);
    final catCtrl = TextEditingController(text: skill?.categorie);
    int niveau = skill?.niveau ?? 3;

    showFormSheet(
      context: context,
      title: skill == null ? 'Ajouter une compétence' : 'Modifier la compétence',
      icon: Icons.psychology_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Compétence *',
              hintText: 'Ex : JavaScript, Python, Photoshop...',
              prefixIcon: Icon(Icons.code_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: catCtrl,
            decoration: const InputDecoration(
              labelText: 'Catégorie (optionnel)',
              hintText: 'Ex : Développement, Design, Gestion...',
              prefixIcon: Icon(Icons.folder_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          // Niveau
          Row(
            children: [
              Text(
                'Niveau',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _levelLabel(niveau),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(ctx).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: niveau.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _levelLabel(niveau),
              onChanged: (v) => setState(() => niveau = v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Débutant',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45))),
              Text('Expert',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45))),
            ],
          ),
        ],
      ),
      onSave: () {
        if (nomCtrl.text.isNotEmpty) {
          onSave(Skill(
            id: skill?.id,
            nom: nomCtrl.text,
            niveau: niveau,
            categorie: catCtrl.text.isNotEmpty ? catCtrl.text : null,
          ));
        }
      },
    );
  }

  static String _levelLabel(int n) => switch (n) {
        1 => 'Débutant',
        2 => 'Intermédiaire',
        3 => 'Avancé',
        4 => 'Confirmé',
        _ => 'Expert',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skills.isEmpty)
          const SectionEmptyState(
            icon: Icons.psychology_outlined,
            label: 'Aucune compétence ajoutée',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return _SkillChip(
                skill: s,
                onEdit: () => _edit(context, i),
                onDelete: () => _delete(i),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter une compétence',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final Skill skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SkillChip({
    required this.skill,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          Text(
            skill.nom ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
          // Niveau en points
          const SizedBox(width: 6),
          Row(
            children: List.generate(
              5,
              (i) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < (skill.niveau ?? 0)
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onEdit,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Icon(Icons.edit_outlined,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.7)),
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
              child: Icon(Icons.close_rounded,
                  size: 14, color: colorScheme.error.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
