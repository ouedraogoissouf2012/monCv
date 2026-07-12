import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
    final etablissementCtrl = TextEditingController(text: edu?.etablissement);
    final diplomeCtrl = TextEditingController(text: edu?.diplome);
    final domaineCtrl = TextEditingController(text: edu?.domaine);
    final descCtrl = TextEditingController(text: edu?.description);
    DateTime? debut = edu?.dateDebut;
    DateTime? fin = edu?.dateFin;
    bool enCours = edu?.dateFin == null && edu != null ? false : false;

    showFormSheet(
      context: context,
      title: edu == null ? l.addEducation : l.editEducation,
      icon: Icons.school_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: etablissementCtrl,
            decoration: InputDecoration(
              labelText: '${l.establishment} *',
              prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: diplomeCtrl,
            decoration: InputDecoration(
              labelText: '${l.degree} *',
              prefixIcon: const Icon(Icons.workspace_premium_outlined, size: 20),
            ),
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
      onSave: () => onSave(Education(
        id: edu?.id,
        etablissement: etablissementCtrl.text,
        diplome: diplomeCtrl.text,
        domaine: domaineCtrl.text,
        dateDebut: debut,
        dateFin: enCours ? null : fin,
        description: descCtrl.text,
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
        if (educations.isEmpty)
          SectionEmptyState(
            icon: Icons.school_outlined,
            label: l.noneEducation,
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
                    : edu.etablissement ?? l.untitled,
                subtitle: edu.etablissement ?? '',
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: l.addEducation,
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
