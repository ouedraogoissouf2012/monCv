import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import '../../../utils/constants.dart';

class SkillsSection extends StatelessWidget {
  final List<Skill> skills;
  final Function(List<Skill>) onChanged;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  void _addSkill(BuildContext context) {
    _showSkillDialog(context, null, (skill) {
      onChanged([...skills, skill]);
    });
  }

  void _editSkill(BuildContext context, int index) {
    _showSkillDialog(context, skills[index], (skill) {
      final newList = List<Skill>.from(skills);
      newList[index] = skill;
      onChanged(newList);
    });
  }

  void _deleteSkill(int index) {
    final newList = List<Skill>.from(skills);
    newList.removeAt(index);
    onChanged(newList);
  }

  void _showSkillDialog(
    BuildContext context,
    Skill? skill,
    Function(Skill) onSave,
  ) {
    final nomController = TextEditingController(text: skill?.nom);
    final categorieController = TextEditingController(text: skill?.categorie);
    int niveau = skill?.niveau ?? 3;

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
                skill == null ? 'Ajouter une competence' : 'Modifier la competence',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Competence',
                  hintText: 'Ex: JavaScript, Python, Excel...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categorieController,
                decoration: const InputDecoration(
                  labelText: 'Categorie (optionnel)',
                  hintText: 'Ex: Programmation, Bureautique...',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Niveau: $niveau/5',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Slider(
                value: niveau.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getLevelLabel(niveau),
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => niveau = value.toInt());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Debutant', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Expert', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (nomController.text.isNotEmpty) {
                    onSave(Skill(
                      id: skill?.id,
                      nom: nomController.text,
                      niveau: niveau,
                      categorie: categorieController.text.isNotEmpty
                          ? categorieController.text
                          : null,
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

  String _getLevelLabel(int niveau) {
    switch (niveau) {
      case 1:
        return 'Debutant';
      case 2:
        return 'Intermediaire';
      case 3:
        return 'Avance';
      case 4:
        return 'Confirme';
      case 5:
        return 'Expert';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (skills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Aucune competence',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(skill.nom ?? ''),
                  subtitle: skill.categorie != null ? Text(skill.categorie!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: i < (skill.niveau ?? 0)
                                ? AppColors.warning
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editSkill(context, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                        onPressed: () => _deleteSkill(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        OutlinedButton.icon(
          onPressed: () => _addSkill(context),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une competence'),
        ),
      ],
    );
  }
}
