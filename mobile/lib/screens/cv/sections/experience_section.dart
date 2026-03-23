import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../utils/constants.dart';

class ExperienceSection extends StatelessWidget {
  final List<Experience> experiences;
  final Function(List<Experience>) onChanged;

  const ExperienceSection({
    super.key,
    required this.experiences,
    required this.onChanged,
  });

  void _addExperience(BuildContext context) {
    _showExperienceDialog(context, null, (experience) {
      onChanged([...experiences, experience]);
    });
  }

  void _editExperience(BuildContext context, int index) {
    _showExperienceDialog(context, experiences[index], (experience) {
      final newList = List<Experience>.from(experiences);
      newList[index] = experience;
      onChanged(newList);
    });
  }

  void _deleteExperience(int index) {
    final newList = List<Experience>.from(experiences);
    newList.removeAt(index);
    onChanged(newList);
  }

  void _showExperienceDialog(
    BuildContext context,
    Experience? experience,
    Function(Experience) onSave,
  ) {
    final entrepriseController =
        TextEditingController(text: experience?.entreprise);
    final posteController = TextEditingController(text: experience?.poste);
    final lieuController = TextEditingController(text: experience?.lieu);
    final descriptionController =
        TextEditingController(text: experience?.description);
    DateTime? dateDebut = experience?.dateDebut;
    DateTime? dateFin = experience?.dateFin;
    bool actuel = experience?.actuel ?? false;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  experience == null ? 'Ajouter une experience' : 'Modifier l\'experience',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: posteController,
                  decoration: const InputDecoration(labelText: 'Poste'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: entrepriseController,
                  decoration: const InputDecoration(labelText: 'Entreprise'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lieuController,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Poste actuel'),
                  value: actuel,
                  onChanged: (value) {
                    setState(() {
                      actuel = value ?? false;
                      if (actuel) dateFin = null;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Debut'),
                        subtitle: Text(
                          dateDebut != null
                              ? '${dateDebut!.month}/${dateDebut!.year}'
                              : 'Selectionner',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateDebut ?? DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => dateDebut = date);
                          }
                        },
                      ),
                    ),
                    if (!actuel)
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fin'),
                          subtitle: Text(
                            dateFin != null
                                ? '${dateFin!.month}/${dateFin!.year}'
                                : 'Selectionner',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateFin ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => dateFin = date);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description des taches',
                    hintText: 'Decrivez vos responsabilites...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    onSave(Experience(
                      id: experience?.id,
                      entreprise: entrepriseController.text,
                      poste: posteController.text,
                      lieu: lieuController.text,
                      dateDebut: dateDebut,
                      dateFin: dateFin,
                      description: descriptionController.text,
                      actuel: actuel,
                    ));
                    Navigator.pop(context);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: experiences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune experience',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: experiences.length,
                  itemBuilder: (context, index) {
                    final exp = experiences[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(exp.poste ?? 'Sans titre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.entreprise ?? ''),
                            if (exp.actuel)
                              const Text(
                                'Poste actuel',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editExperience(context, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteExperience(index),
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
            onPressed: () => _addExperience(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une experience'),
          ),
        ),
      ],
    );
  }
}
