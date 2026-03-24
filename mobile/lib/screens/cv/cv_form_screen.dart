import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../utils/constants.dart';
import 'sections/personal_info_section.dart';
import 'sections/education_section.dart';
import 'sections/experience_section.dart';
import 'sections/skills_section.dart';
import 'sections/languages_section.dart';

class CvFormScreen extends StatefulWidget {
  final Cv? cv;

  const CvFormScreen({super.key, this.cv});

  @override
  State<CvFormScreen> createState() => _CvFormScreenState();
}

class _CvFormScreenState extends State<CvFormScreen> {
  final _titreFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  PersonalInfo? _personalInfo;
  List<Education> _educations = [];
  List<Experience> _experiences = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];

  bool _isLoading = false;

  bool get isEditing => widget.cv != null;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cv?.titre ?? '');

    if (widget.cv != null) {
      _personalInfo = widget.cv!.personalInfo;
      _educations = List.from(widget.cv!.educations);
      _experiences = List.from(widget.cv!.experiences);
      _skills = List.from(widget.cv!.skills);
      _languages = List.from(widget.cv!.languages);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final titreOk = _titreFormKey.currentState?.validate() ?? false;
    final infoOk = _personalInfoFormKey.currentState?.validate() ?? false;
    if (!titreOk || !infoOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les champs obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Capture context-dependent objects BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _isLoading = true);

    final cv = Cv(
      id: widget.cv?.id,
      titre: _titreController.text,
      personalInfo: _personalInfo,
      educations: _educations,
      experiences: _experiences,
      skills: _skills,
      languages: _languages,
    );

    final cvProvider = context.read<CvProvider>();
    bool success;

    if (isEditing) {
      success = await cvProvider.updateCv(widget.cv!.id!, cv);
    } else {
      success = await cvProvider.createCv(cv);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      router.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'CV mis a jour' : 'CV cree avec succes'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(cvProvider.error ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le CV' : 'Nouveau CV'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Titre du CV
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _titreFormKey,
                        child: TextFormField(
                          controller: _titreController,
                          decoration: const InputDecoration(
                            labelText: 'Titre du CV *',
                            hintText: 'Ex: Developpeur Full Stack',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
                        ),
                      ),
                    ),
                  ),

                  _SectionCard(
                    title: 'Informations personnelles',
                    icon: Icons.person_outline,
                    child: PersonalInfoSection(
                      personalInfo: _personalInfo,
                      onChanged: (info) => setState(() => _personalInfo = info),
                      formKey: _personalInfoFormKey,
                    ),
                  ),
                  _SectionCard(
                    title: 'Expériences',
                    icon: Icons.work_outline,
                    child: ExperienceSection(
                      experiences: _experiences,
                      onChanged: (list) => setState(() => _experiences = list),
                    ),
                  ),
                  _SectionCard(
                    title: 'Formations',
                    icon: Icons.school_outlined,
                    child: EducationSection(
                      educations: _educations,
                      onChanged: (list) => setState(() => _educations = list),
                    ),
                  ),
                  _SectionCard(
                    title: 'Compétences',
                    icon: Icons.star_outline,
                    child: SkillsSection(
                      skills: _skills,
                      onChanged: (list) => setState(() => _skills = list),
                    ),
                  ),
                  _SectionCard(
                    title: 'Langues',
                    icon: Icons.language_outlined,
                    child: LanguagesSection(
                      languages: _languages,
                      onChanged: (list) => setState(() => _languages = list),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky save button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
