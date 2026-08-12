import 'package:flutter/material.dart';

import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../features/cv/presentation/section_editor/section_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/domain/entities/language.dart';
import '../../../utils/cv_levels.dart';

class LanguagesSection extends StatelessWidget {
  final List<Language> languages;
  final Function(List<Language>) onChanged;

  const LanguagesSection({
    super.key,
    required this.languages,
    required this.onChanged,
  });

  static const _niveaux = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'NATIF'];

  // Liste de langues pour l'autocompletion.
  static const _allLanguages = [
    'Français',
    'Anglais',
    'Espagnol',
    'Portugais',
    'Allemand',
    'Italien',
    'Néerlandais',
    'Russe',
    'Chinois (Mandarin)',
    'Japonais',
    'Coréen',
    'Arabe',
    'Hindi',
    'Bengali',
    'Turc',
    'Vietnamien',
    'Thaïlandais',
    'Polonais',
    'Ukrainien',
    'Roumain',
    'Tchèque',
    'Grec',
    'Hongrois',
    'Suédois',
    'Norvégien',
    'Danois',
    'Finnois',
    'Hébreu',
    'Persan',
    'Swahili',
    'Haoussa',
    'Yoruba',
    'Igbo',
    'Amharique',
    'Somali',
    'Wolof',
    'Bambara',
    'Dioula',
    'Lingala',
    'Kikongo',
    'Peul',
    'Mooré',
    'Baoulé',
    'Bété',
    'Sénoufo',
    'Malinké',
    'Soussou',
    'Créole',
    'Tamoul',
    'Ourdou',
    'Malais',
    'Indonésien',
    'Tagalog',
    'Catalan',
    'Basque',
    'Galicien',
    'Serbe',
    'Croate',
    'Bosniaque',
    'Bulgare',
    'Slovaque',
    'Slovène',
    'Lituanien',
    'Letton',
    'Estonien',
    'Géorgien',
    'Arménien',
    'Kazakh',
    'Ouzbek',
    'Azerbaïdjanais',
    'Mongol',
  ];

  /// Ouvre l'editeur de langue et retourne la valeur saisie (ou `null` si
  /// annule / invalide). Langue ET niveau sont requis : tous deux integres a
  /// la validation du Form (le niveau via un FormField dedie), donc la
  /// sauvegarde est bloquee tant que l'un manque.
  Future<Language?> _editSheet(BuildContext context, Language? lang) {
    final l = AppLocalizations.of(context)!;
    String langueText = lang?.langue ?? '';
    String? selectedNiveau = lang?.niveau;

    return showSectionEditor<Language>(
      context: context,
      title: lang == null ? l.addLanguage : l.editLanguage,
      icon: Icons.translate_rounded,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<String>(
            initialValue: TextEditingValue(text: langueText),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const [];
              final query = textEditingValue.text.toLowerCase();
              return _allLanguages
                  .where((name) => name.toLowerCase().startsWith(query));
            },
            onSelected: (String selection) => langueText = selection,
            fieldViewBuilder: (ctx2, ctrl, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: ctrl,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: l.languageRequired,
                  hintText: l.languageSearchHint,
                  prefixIcon: const Icon(Icons.language_rounded, size: 20),
                ),
                onChanged: (v) => langueText = v,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
              );
            },
            optionsViewBuilder: (ctx2, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 180, maxWidth: 280),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (ctx3, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(option,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            l.levelRequired,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Theme.of(ctx).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          // Le niveau (chips CEFR) est requis : un FormField l'integre a la
          // validation du Form pour bloquer la sauvegarde s'il manque.
          FormField<String>(
            initialValue: selectedNiveau,
            validator: (v) => v == null ? l.fieldRequired : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _niveaux.map((n) {
                    final selected = selectedNiveau == n;
                    final colorScheme = Theme.of(ctx).colorScheme;
                    return GestureDetector(
                      onTap: () {
                        final next = selected ? null : n;
                        setState(() => selectedNiveau = next);
                        state.didChange(next);
                      },
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
                              localizedLanguageLevelLabel(l, n),
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
                if (state.hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      buildResult: () => Language(
        id: lang?.id,
        langue: langueText.trim(),
        niveau: selectedNiveau,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Language>(
      items: languages,
      onChanged: onChanged,
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addLanguage,
      emptyIcon: Icons.translate_rounded,
      emptyLabel: l.noneLanguage,
      itemBuilder: (ctx, lang, index,
          {required onEditItem, required onDeleteItem}) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SectionItemTile(
          title: lang.langue ?? '',
          subtitle: lang.niveau != null
              ? '${lang.niveau} — ${localizedLanguageLevelLabel(l, lang.niveau)}'
              : '',
          badge: lang.niveau == 'NATIF' ? l.native : null,
          badgeColor: colorScheme.primary,
          onEdit: onEditItem,
          onDelete: onDeleteItem,
        );
      },
    );
  }
}
