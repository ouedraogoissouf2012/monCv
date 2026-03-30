import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../services/api_service.dart';
import 'form_sheet.dart';

Future<void> showSuggestionsSheet(
  BuildContext context,
  List<String> suggestions,
  TextEditingController controller,
) {
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18),
                SizedBox(width: 8),
                Text(
                  'Suggestions IA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Appuyez sur une suggestion pour l\'ajouter à la description.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  controller.text =
                      current.isEmpty ? '• ${suggestions[i]}' : '$current\n• ${suggestions[i]}';
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('• ${suggestions[i]}', style: const TextStyle(fontSize: 13)),
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
          const SizedBox(height: 6),
          AiSuggestButton(
            isLoading: isLoadingAi,
            onPressed: () async {
              setState(() => isLoadingAi = true);
              try {
                final suggestions = await ApiService().getAiSuggestions(
                  poste: posteCtrl.text,
                  entreprise: entrepriseCtrl.text,
                );
                if (!ctx.mounted) return;
                await showSuggestionsSheet(ctx, suggestions, descCtrl);
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Suggestions IA indisponibles — clé OpenAI non configurée sur le serveur',
                    ),
                    backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    action: SnackBarAction(
                      label: 'OK',
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
