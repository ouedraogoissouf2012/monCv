import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../utils/constants.dart';

class EducationSection extends StatelessWidget {
  final List<Education> educations;
  final Function(List<Education>) onChanged;

  const EducationSection({
    super.key,
    required this.educations,
    required this.onChanged,
  });

  void _addEducation(BuildContext context) {
    _showEducationDialog(context, null, (education) {
      onChanged([...educations, education]);
    });
  }

  void _editEducation(BuildContext context, int index) {
    _showEducationDialog(context, educations[index], (education) {
      final newList = List<Education>.from(educations);
      newList[index] = education;
      onChanged(newList);
    });
  }

  void _deleteEducation(int index) {
    final newList = List<Education>.from(educations);
    newList.removeAt(index);
    onChanged(newList);
  }

  void _showEducationDialog(
    BuildContext context,
    Education? education,
    Function(Education) onSave,
  ) {
    final etablissementController =
        TextEditingController(text: education?.etablissement);
    final diplomeController = TextEditingController(text: education?.diplome);
    final domaineController = TextEditingController(text: education?.domaine);
    final descriptionController =
        TextEditingController(text: education?.description);
    DateTime? dateDebut = education?.dateDebut;
    DateTime? dateFin = education?.dateFin;

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
                  education == null ? 'Ajouter une formation' : 'Modifier la formation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: etablissementController,
                  decoration: const InputDecoration(labelText: 'Etablissement'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: diplomeController,
                  decoration: const InputDecoration(labelText: 'Diplome'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: domaineController,
                  decoration: const InputDecoration(labelText: 'Domaine'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Debut'),
                        subtitle: Text(
                          dateDebut != null
                              ? '${dateDebut!.year}'
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
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fin'),
                        subtitle: Text(
                          dateFin != null
                              ? '${dateFin!.year}'
                              : 'Selectionner',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateFin ?? DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    onSave(Education(
                      id: education?.id,
                      etablissement: etablissementController.text,
                      diplome: diplomeController.text,
                      domaine: domaineController.text,
                      dateDebut: dateDebut,
                      dateFin: dateFin,
                      description: descriptionController.text,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (educations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Aucune formation',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: educations.length,
            itemBuilder: (context, index) {
              final edu = educations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(edu.diplome ?? 'Sans titre'),
                  subtitle: Text(edu.etablissement ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editEducation(context, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _deleteEducation(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        OutlinedButton.icon(
          onPressed: () => _addEducation(context),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une formation'),
        ),
      ],
    );
  }
}
