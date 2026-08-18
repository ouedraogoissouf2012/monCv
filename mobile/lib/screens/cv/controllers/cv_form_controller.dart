import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../models/cv_style.dart';
import '../../../repositories/cv_repository.dart';
import '../validators/cv_form_validator.dart';

typedef CvTitleBuilder = String Function(String firstName, String lastName);

class CvFormController extends ChangeNotifier {
  CvFormController({
    required CvRepository repository,
    Cv? initialCv,
    required String fallbackTitle,
    CvTitleBuilder? titleBuilder,
  })  : _repository = repository,
        _initialCv = initialCv,
        _fallbackTitle = fallbackTitle,
        _titleBuilder = titleBuilder,
        _personalInfo = initialCv?.personalInfo,
        _educations = List.of(initialCv?.educations ?? const []),
        _experiences = List.of(initialCv?.experiences ?? const []),
        _skills = List.of(initialCv?.skills ?? const []),
        _languages = List.of(initialCv?.languages ?? const []),
        _certifications = List.of(initialCv?.certifications ?? const []),
        _projects = List.of(initialCv?.projects ?? const []);

  final CvRepository _repository;
  final Cv? _initialCv;
  final String _fallbackTitle;
  final CvTitleBuilder? _titleBuilder;

  PersonalInfo? _personalInfo;
  List<Education> _educations;
  List<Experience> _experiences;
  List<Skill> _skills;
  List<Language> _languages;
  List<Certification> _certifications;
  List<Project> _projects;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;
  Cv? _savedCv;

  PersonalInfo? get personalInfo => _personalInfo;
  List<Education> get educations => List.unmodifiable(_educations);
  List<Experience> get experiences => List.unmodifiable(_experiences);
  List<Skill> get skills => List.unmodifiable(_skills);
  List<Language> get languages => List.unmodifiable(_languages);
  List<Certification> get certifications => List.unmodifiable(_certifications);
  List<Project> get projects => List.unmodifiable(_projects);
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isEditing => _initialCv != null;
  String? get error => _error;
  Cv? get savedCv => _savedCv;

  Cv get currentCv {
    final base = _initialCv;
    return Cv(
      id: base?.id,
      titre: base?.titre ?? _autoTitle,
      personalInfo: _personalInfo,
      educations: _educations,
      experiences: _experiences,
      skills: _skills,
      languages: _languages,
      certifications: _certifications,
      projects: _projects,
      viewCount: base?.viewCount ?? 0,
      parentCvId: base?.parentCvId,
      varianteLabel: base?.varianteLabel,
      variantCount: base?.variantCount,
      shareToken: base?.shareToken,
      publicEnabled: base?.publicEnabled ?? false,
      publicDownloadsEnabled: base?.publicDownloadsEnabled ?? false,
      publicContactEnabled: base?.publicContactEnabled ?? false,
      downloadCount: base?.downloadCount ?? 0,
      shareCount: base?.shareCount ?? 0,
      createdAt: base?.createdAt,
      updatedAt: base?.updatedAt,
      style: base?.style ?? const CvStyle(),
    );
  }

  Map<CvFormSection, CvFormValidationState> get validation =>
      CvFormValidator.validationFor(currentCv);
  int get readinessScore => CvFormValidator.readinessScore(currentCv);
  bool stepComplete(int index) =>
      CvFormValidator.stepComplete(currentCv, index);

  String get _autoTitle {
    final jobTitle = _personalInfo?.titrePoste?.trim();
    if (jobTitle?.isNotEmpty == true) return jobTitle!;
    final firstName = _personalInfo?.prenom?.trim() ?? '';
    final lastName = _personalInfo?.nom?.trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return (_titleBuilder?.call(firstName, lastName) ??
              '$firstName $lastName')
          .trim();
    }
    return _fallbackTitle;
  }

  void updatePersonalInfo(PersonalInfo? value) {
    _personalInfo = value;
    notifyListeners();
  }

  void updateExperiences(List<Experience> values) {
    _experiences = List.of(values);
    notifyListeners();
  }

  void addExperience(Experience value) =>
      updateExperiences([..._experiences, value]);

  void updateEducations(List<Education> values) {
    _educations = List.of(values);
    notifyListeners();
  }

  void addEducation(Education value) =>
      updateEducations([..._educations, value]);

  void updateSkills(List<Skill> values) {
    _skills = List.of(values);
    notifyListeners();
  }

  void addSkill(Skill value) => updateSkills([..._skills, value]);

  void updateLanguages(List<Language> values) {
    _languages = List.of(values);
    notifyListeners();
  }

  void addLanguage(Language value) => updateLanguages([..._languages, value]);

  void updateCertifications(List<Certification> values) {
    _certifications = List.of(values);
    notifyListeners();
  }

  void addCertification(Certification value) =>
      updateCertifications([..._certifications, value]);

  void updateProjects(List<Project> values) {
    _projects = List.of(values);
    notifyListeners();
  }

  void addProject(Project value) => updateProjects([..._projects, value]);

  bool goToStep(int step, {bool allowForward = true}) {
    if (step < 0 || step >= CvFormSection.values.length) return false;
    if (step > _currentStep && !allowForward) return false;
    if (_currentStep == step) return true;
    _currentStep = step;
    notifyListeners();
    return true;
  }

  Future<bool> save() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cv = currentCv;
    final Result<Cv> result = isEditing
        ? await _repository.updateCv(_initialCv!.id!, cv)
        : await _repository.createCv(cv);

    _isLoading = false;
    switch (result) {
      case Success(:final data):
        _savedCv = data;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message.replaceFirst(RegExp(r'^Exception:\s*'), '');
        notifyListeners();
        return false;
    }
  }
}
