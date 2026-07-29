import 'package:flutter/material.dart';

import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/cv.dart';
import '../../../utils/cv_levels.dart';

class SkillsSection extends StatelessWidget {
  final List<Skill> skills;
  final Function(List<Skill>) onChanged;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  /// Ouvre l'editeur de competence et retourne la valeur saisie (ou `null` si
  /// annule / invalide). Ne mute jamais la liste parent.
  Future<Skill?> _editSheet(BuildContext context, Skill? skill) {
    final l = AppLocalizations.of(context)!;
    final nomCtrl = TextEditingController(text: skill?.nom);
    final catCtrl = TextEditingController(text: skill?.categorie);
    int niveau = skill?.niveau ?? 3;

    return showSectionEditor<Skill>(
      context: context,
      title: skill == null ? l.addSkill : l.editSkill,
      icon: Icons.psychology_outlined,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: InputDecoration(
              labelText: l.skillRequired,
              hintText: l.skillHint,
              prefixIcon: const Icon(Icons.code_rounded, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: catCtrl,
            decoration: InputDecoration(
              labelText: l.optionalCategory,
              hintText: l.categoryHint,
              prefixIcon: const Icon(Icons.folder_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                l.level,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  localizedSkillLevelLabel(l, niveau),
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
              label: localizedSkillLevelLabel(l, niveau),
              onChanged: (v) => setState(() => niveau = v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.beginner,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45))),
              Text(l.expert,
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
      buildResult: () => Skill(
        id: skill?.id,
        nom: nomCtrl.text.trim(),
        niveau: niveau,
        categorie: catCtrl.text.isNotEmpty ? catCtrl.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Skill>(
      items: skills,
      onChanged: onChanged,
      layout: SectionListLayout.wrap,
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addSkill,
      emptyIcon: Icons.psychology_outlined,
      emptyLabel: l.noneSkill,
      itemBuilder: (ctx, skill, index,
              {required onEditItem, required onDeleteItem}) =>
          _SkillChip(
        skill: skill,
        onEdit: onEditItem,
        onDelete: onDeleteItem,
      ),
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
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
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
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Icon(Icons.edit_outlined,
                  size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(20)),
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
