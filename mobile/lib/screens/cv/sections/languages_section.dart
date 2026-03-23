import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../utils/constants.dart';

class LanguagesSection extends StatelessWidget {
  final List<Language> languages;
  final Function(List<Language>) onChanged;

  const LanguagesSection({
    super.key,
    required this.languages,
    required this.onChanged,
  });

  static const List<String> niveaux = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
    'NATIF',
  ];

  static const Map<String, String> niveauDescriptions = {
    'A1': 'Debutant',
    'A2': 'Elementaire',
    'B1': 'Intermediaire',
    'B2': 'Intermediaire avance',
    'C1': 'Avance',
    'C2': 'Maitrise',
    'NATIF': 'Langue maternelle',
  };

  void _addLanguage(BuildContext context) {
    _showLanguageDialog(context, null, (language) {
      onChanged([...languages, language]);
    });
  }

  void _editLanguage(BuildContext context, int index) {
    _showLanguageDialog(context, languages[index], (language) {
      final newList = List<Language>.from(languages);
      newList[index] = language;
      onChanged(newList);
    });
  }

  void _deleteLanguage(int index) {
    final newList = List<Language>.from(languages);
    newList.removeAt(index);
    onChanged(newList);
  }

  void _showLanguageDialog(
    BuildContext context,
    Language? language,
    Function(Language) onSave,
  ) {
    final langueController = TextEditingController(text: language?.langue);
    String? selectedNiveau = language?.niveau;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                language == null ? 'Ajouter une langue' : 'Modifier la langue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: langueController,
                decoration: const InputDecoration(
                  labelText: 'Langue',
                  hintText: 'Ex: Francais, Anglais, Espagnol...',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Niveau',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: niveaux.map((niveau) {
                  final isSelected = selectedNiveau == niveau;
                  return ChoiceChip(
                    label: Text(niveau),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedNiveau = selected ? niveau : null);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              if (selectedNiveau != null) ...[
                const SizedBox(height: 8),
                Text(
                  niveauDescriptions[selectedNiveau] ?? '',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (langueController.text.isNotEmpty && selectedNiveau != null) {
                    onSave(Language(
                      id: language?.id,
                      langue: langueController.text,
                      niveau: selectedNiveau,
                    ));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: languages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune langue',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            lang.langue?.substring(0, 2).toUpperCase() ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(lang.langue ?? ''),
                        subtitle: Text(
                          '${lang.niveau} - ${niveauDescriptions[lang.niveau] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editLanguage(context, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                              onPressed: () => _deleteLanguage(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _addLanguage(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une langue'),
          ),
        ),
      ],
    );
  }
}
