import 'package:flutter/material.dart';

import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../features/cv/presentation/section_editor/section_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/domain/entities/education.dart';
import '../../../features/cv/presentation/section_editor/section_form_fields.dart'
    show SectionDateButton;

class EducationSection extends StatelessWidget {
  final List<Education> educations;
  final Function(List<Education>) onChanged;

  const EducationSection({
    super.key,
    required this.educations,
    required this.onChanged,
  });

  /// Ouvre l'editeur de formation et retourne la valeur saisie (ou `null` si
  /// annule / invalide). Ne mute jamais la liste parent.
  Future<Education?> _editSheet(BuildContext context, Education? edu) {
    final l = AppLocalizations.of(context)!;
    final etablissementCtrl = TextEditingController(text: edu?.etablissement);
    final diplomeCtrl = TextEditingController(text: edu?.diplome);
    final domaineCtrl = TextEditingController(text: edu?.domaine);
    final descCtrl = TextEditingController(text: edu?.description);
    DateTime? debut = edu?.dateDebut;
    DateTime? fin = edu?.dateFin;
    // Une formation existante sans date de fin est consideree « en cours ».
    // (Corrige l'ancien `... ? false : false` qui restait toujours faux.)
    bool enCours = edu != null && edu.dateFin == null;

    return showSectionEditor<Education>(
      context: context,
      title: edu == null ? l.addEducation : l.editEducation,
      icon: Icons.school_outlined,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: etablissementCtrl,
            decoration: InputDecoration(
              labelText: '${l.establishment} *',
              prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: diplomeCtrl,
            decoration: InputDecoration(
              labelText: '${l.degree} *',
              prefixIcon:
                  const Icon(Icons.workspace_premium_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: domaineCtrl,
            decoration: InputDecoration(
              labelText: l.fieldOfStudy,
              prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 12),
              Expanded(
                child: enCours
                    ? Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            l.inProgress,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : SectionDateButton(
                        label: l.end,
                        date: fin,
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: fin ?? DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                          );
                          if (d != null) setState(() => fin = d);
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: enCours,
            onChanged: (v) => setState(() {
              enCours = v ?? false;
              if (enCours) fin = null;
            }),
            title: Text(l.educationInProgress,
                style: const TextStyle(fontSize: 13)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: descCtrl,
            decoration: InputDecoration(
              labelText: l.optionalDescription,
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      buildResult: () => Education(
        id: edu?.id,
        etablissement: etablissementCtrl.text.trim(),
        diplome: diplomeCtrl.text.trim(),
        domaine: domaineCtrl.text,
        dateDebut: debut,
        dateFin: enCours ? null : fin,
        description: descCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Education>(
      items: educations,
      onChanged: onChanged,
      reorderable: true,
      keyOf: (edu, index) => ValueKey('edu-${edu.id ?? index}'),
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addEducation,
      emptyIcon: Icons.school_outlined,
      emptyLabel: l.noneEducation,
      itemBuilder: (ctx, edu, index,
              {required onEditItem, required onDeleteItem}) =>
          SectionItemTile(
        title: edu.diplome?.isNotEmpty == true
            ? edu.diplome!
            : edu.etablissement ?? l.untitled,
        subtitle: edu.etablissement ?? '',
        onEdit: onEditItem,
        onDelete: onDeleteItem,
      ),
    );
  }
}
