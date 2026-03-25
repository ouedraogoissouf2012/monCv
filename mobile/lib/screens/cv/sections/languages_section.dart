import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import 'form_sheet.dart';

class LanguagesSection extends StatelessWidget {
  final List<Language> languages;
  final Function(List<Language>) onChanged;

  const LanguagesSection({
    super.key,
    required this.languages,
    required this.onChanged,
  });

  static const _niveaux = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'NATIF'];
  static const _descriptions = {
    'A1': 'Débutant',
    'A2': 'Élémentaire',
    'B1': 'Intermédiaire',
    'B2': 'Interm. avancé',
    'C1': 'Avancé',
    'C2': 'Maîtrise',
    'NATIF': 'Langue maternelle',
  };

  void _add(BuildContext context) =>
      _showSheet(context, null, (l) => onChanged([...languages, l]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, languages[i], (l) {
        final list = List<Language>.from(languages);
        list[i] = l;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Language>.from(languages);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Language? lang,
    Function(Language) onSave,
  ) {
    final langCtrl = TextEditingController(text: lang?.langue);
    String? selectedNiveau = lang?.niveau;

    showFormSheet(
      context: context,
      title: lang == null ? 'Ajouter une langue' : 'Modifier la langue',
      icon: Icons.translate_rounded,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: langCtrl,
            decoration: const InputDecoration(
              labelText: 'Langue *',
              hintText: 'Ex : Français, Anglais, Espagnol...',
              prefixIcon: Icon(Icons.language_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NIVEAU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Theme.of(ctx).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _niveaux.map((n) {
              final selected = selectedNiveau == n;
              final colorScheme = Theme.of(ctx).colorScheme;
              return GestureDetector(
                onTap: () => setState(
                    () => selectedNiveau = selected ? null : n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        n,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _descriptions[n] ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.8)
                              : colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      onSave: () {
        if (langCtrl.text.isNotEmpty && selectedNiveau != null) {
          onSave(Language(
            id: lang?.id,
            langue: langCtrl.text,
            niveau: selectedNiveau,
          ));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (languages.isEmpty)
          const SectionEmptyState(
            icon: Icons.translate_rounded,
            label: 'Aucune langue ajoutée',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: languages.length,
            itemBuilder: (ctx, i) {
              final lang = languages[i];
              final colorScheme = Theme.of(ctx).colorScheme;
              return SectionItemTile(
                title: lang.langue ?? '',
                subtitle: lang.niveau != null
                    ? '${lang.niveau} — ${_descriptions[lang.niveau] ?? ''}'
                    : '',
                badge: lang.niveau == 'NATIF' ? 'Natif' : null,
                badgeColor: colorScheme.primary,
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter une langue',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
