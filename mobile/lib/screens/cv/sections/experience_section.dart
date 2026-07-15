import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/cv.dart';
import '../../../services/i_api_client.dart';
import 'form_sheet.dart';

Future<void> showSuggestionsSheet(
  BuildContext context,
  List<String> suggestions,
  TextEditingController controller,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text(
                  l.aiSuggestions,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l.tapSuggestion,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => InkWell(
                onTap: () {
                  final current = controller.text.trim();
                  controller.text = current.isEmpty
                      ? '• ${suggestions[i]}'
                      : '$current\n• ${suggestions[i]}';
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('• ${suggestions[i]}',
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

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
    final l = AppLocalizations.of(context)!;
    final posteCtrl = TextEditingController(text: exp?.poste);
    final entrepriseCtrl = TextEditingController(text: exp?.entreprise);
    final lieuCtrl = TextEditingController(text: exp?.lieu);
    final descCtrl = TextEditingController(text: exp?.description);
    DateTime? debut = exp?.dateDebut;
    DateTime? fin = exp?.dateFin;
    bool actuel = exp?.actuel ?? false;
    bool isLoadingAi = false;

    showFormSheet(
      context: context,
      title: exp == null ? l.addExperience : l.editExperience,
      icon: Icons.work_outline_rounded,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: posteCtrl,
            decoration: InputDecoration(
              labelText: l.jobTitleRequired,
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: entrepriseCtrl,
            decoration: InputDecoration(
              labelText: l.companyRequired,
              prefixIcon: const Icon(Icons.business_outlined, size: 20),
            ),
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
              try {
                final suggestions =
                    await ctx.read<IApiClient>().getAiSuggestions(
                          poste: posteCtrl.text,
                          entreprise: entrepriseCtrl.text,
                        );
                if (!ctx.mounted) return;
                await showSuggestionsSheet(ctx, suggestions, descCtrl);
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      l.aiSuggestionsUnavailable,
                    ),
                    backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    action: SnackBarAction(
                      label: l.close,
                      onPressed: () {},
                    ),
                  ),
                );
              } finally {
                if (ctx.mounted) setState(() => isLoadingAi = false);
              }
            },
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
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (experiences.isEmpty)
          SectionEmptyState(
            icon: Icons.work_outline_rounded,
            label: l.noneExperience,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experiences.length,
            itemBuilder: (ctx, i) {
              final exp = experiences[i];
              return SectionItemTile(
                title: exp.poste?.isNotEmpty == true ? exp.poste! : l.untitled,
                subtitle: exp.entreprise ?? '',
                badge: exp.actuel ? l.currentPosition : null,
                badgeColor: Colors.green,
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: l.addExperience,
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
