import 'package:flutter/material.dart';
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
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 5;

  final _titreFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  PersonalInfo? _personalInfo;
  List<Education> _educations = [];
  List<Experience> _experiences = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];

  bool get isEditing => widget.cv != null;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _pageController.dispose();
    _titreController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      final titreOk = _titreFormKey.currentState?.validate() ?? false;
      final infoOk = _personalInfoFormKey.currentState?.validate() ?? false;
      if (!titreOk || !infoOk) return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveCv() async {
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

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'CV mis a jour' : 'CV cree avec succes'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        title: Text(isEditing ? AppStrings.editCv : AppStrings.createCv),
        actions: [
          TextButton(
            onPressed: _saveCv,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Titre du CV
          Padding(
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
            ),
          ),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_totalPages, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Page title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getPageTitle(_currentPage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                PersonalInfoSection(
                  personalInfo: _personalInfo,
                  onChanged: (info) => setState(() => _personalInfo = info),
                  formKey: _personalInfoFormKey,
                ),
                EducationSection(
                  educations: _educations,
                  onChanged: (list) => setState(() => _educations = list),
                ),
                ExperienceSection(
                  experiences: _experiences,
                  onChanged: (list) => setState(() => _experiences = list),
                ),
                SkillsSection(
                  skills: _skills,
                  onChanged: (list) => setState(() => _skills = list),
                ),
                LanguagesSection(
                  languages: _languages,
                  onChanged: (list) => setState(() => _languages = list),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Precedent'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _currentPage < _totalPages - 1 ? _nextPage : _saveCv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentPage < _totalPages - 1 ? 'Suivant' : 'Terminer',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int page) {
    switch (page) {
      case 0:
        return 'Informations personnelles';
      case 1:
        return 'Formations';
      case 2:
        return 'Experiences';
      case 3:
        return 'Competences';
      case 4:
        return 'Langues';
      default:
        return '';
    }
  }
}
