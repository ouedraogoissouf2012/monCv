import '../../../l10n/app_localizations.dart';
import '../../../models/cv.dart';
import '../../../services/cv_validator.dart';

enum CvFormSection { identity, experiences, education, skills, extras }

enum CvFormValidationState { empty, valid, invalid }

class CvFormValidationIssue {
  const CvFormValidationIssue({required this.section, required this.message});

  final CvFormSection section;
  final String message;
}

class CvFormValidator {
  const CvFormValidator._();

  static bool isPersonalInfoValid(PersonalInfo? info) {
    final email = info?.email?.trim();
    return info != null &&
        (info.prenom?.trim().isNotEmpty ?? false) &&
        (info.nom?.trim().isNotEmpty ?? false) &&
        email != null &&
        RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static Map<CvFormSection, CvFormValidationState> validationFor(Cv cv) => {
        CvFormSection.identity: cv.personalInfo == null
            ? CvFormValidationState.empty
            : isPersonalInfoValid(cv.personalInfo)
                ? CvFormValidationState.valid
                : CvFormValidationState.invalid,
        CvFormSection.experiences: _listState(cv.experiences),
        CvFormSection.education: _listState(cv.educations),
        CvFormSection.skills: _combinedListState(cv.skills, cv.languages),
        CvFormSection.extras:
            _combinedListState(cv.certifications, cv.projects),
      };

  static bool stepComplete(Cv cv, int index) {
    final section = CvFormSection.values[index];
    return validationFor(cv)[section] == CvFormValidationState.valid;
  }

  static int completionPercent(Cv cv) {
    final completed = validationFor(cv)
        .values
        .where((state) => state == CvFormValidationState.valid)
        .length;
    return ((completed / CvFormSection.values.length) * 100).round();
  }

  static CvFormValidationIssue? validateForSave(
    Cv cv,
    AppLocalizations localizations,
  ) {
    final issue = CvValidator().validateForSave(cv, localizations);
    if (issue == null) return null;
    return CvFormValidationIssue(
      section: sectionForCategory(issue.category),
      message: issue.message,
    );
  }

  static CvFormSection sectionForCategory(String category) =>
      switch (category) {
        'experiences' => CvFormSection.experiences,
        'formations' => CvFormSection.education,
        'competences' || 'langues' => CvFormSection.skills,
        'certifications' || 'projets' => CvFormSection.extras,
        _ => CvFormSection.identity,
      };

  static CvFormValidationState _listState(List<Object?> values) =>
      values.isEmpty
          ? CvFormValidationState.empty
          : CvFormValidationState.valid;

  static CvFormValidationState _combinedListState(
    List<Object?> first,
    List<Object?> second,
  ) =>
      first.isEmpty && second.isEmpty
          ? CvFormValidationState.empty
          : CvFormValidationState.valid;
}
