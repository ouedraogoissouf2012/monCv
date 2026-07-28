import '../features/cv/domain/policies/cv_validation_thresholds.dart';
import '../models/cv.dart';
import '../l10n/app_localizations.dart';

/// Service de validation intelligente du CV. Seuils : [CvValidationThresholds].
class CvValidator {
  static final CvValidator _instance = CvValidator._();
  CvValidator._();
  factory CvValidator() => _instance;

  /// Valide un CV complet et retourne un rapport.
  ValidationReport validate(Cv cv, AppLocalizations l) {
    final warnings = <ValidationIssue>[];
    final errors = <ValidationIssue>[];

    _validatePersonalInfo(cv.personalInfo, warnings, errors, l);
    _validateExperiences(cv.experiences, warnings, errors, l);
    _validateEducations(cv.educations, warnings, l);
    _validateSkills(cv.skills, warnings, l);
    _validateLanguages(cv.languages, warnings, l);
    _validateCertifications(cv.certifications, warnings, l);
    _validateProjects(cv.projects, warnings, l);
    _validateOverall(cv, warnings, l);

    final deductions = errors.length * CvValidationThresholds.errorPenalty +
        warnings.length * CvValidationThresholds.warningPenalty;
    final score = (CvValidationThresholds.maxScore - deductions)
        .clamp(0, CvValidationThresholds.maxScore);

    return ValidationReport(
      score: score,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Retourne la premiere erreur bloquante avant l'envoi au backend.
  /// Cette validation est alignee sur les contraintes de CvRequest cote API.
  CvSaveValidationIssue? validateForSave(Cv cv, AppLocalizations l) {
    if (_isBlank(cv.titre)) {
      return CvSaveValidationIssue(
        'identite',
        l.requiredFieldMessage(l.identity, l.jobTitle),
      );
    }

    final info = cv.personalInfo;
    if (info == null) {
      return CvSaveValidationIssue(
        'identite',
        l.completePersonalInfo,
      );
    }
    if (_isBlank(info.prenom)) {
      return CvSaveValidationIssue(
        'identite',
        l.requiredFieldMessage(l.identity, l.firstName),
      );
    }
    if (_isBlank(info.nom)) {
      return CvSaveValidationIssue(
        'identite',
        l.requiredFieldMessage(l.identity, l.lastName),
      );
    }
    if (_isBlank(info.email)) {
      return CvSaveValidationIssue(
        'identite',
        l.requiredFieldMessage(l.identity, l.email),
      );
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
        .hasMatch(info.email!.trim())) {
      return CvSaveValidationIssue(
        'identite',
        l.invalidEmailMessage,
      );
    }

    for (var i = 0; i < cv.experiences.length; i++) {
      final exp = cv.experiences[i];
      final label = l.numberedItem(l.experiences, i + 1);
      if (_isBlank(exp.poste)) {
        return CvSaveValidationIssue(
          'experiences',
          l.requiredFieldMessage(label, l.jobTitle),
        );
      }
      if (_isBlank(exp.entreprise)) {
        return CvSaveValidationIssue(
          'experiences',
          l.requiredFieldMessage(label, l.companyRequired.replaceAll(' *', '')),
        );
      }
      if (exp.dateDebut == null) {
        return CvSaveValidationIssue(
          'experiences',
          l.requiredFieldMessage(label, l.start),
        );
      }
      if (exp.dateFin != null && exp.dateFin!.isBefore(exp.dateDebut!)) {
        return CvSaveValidationIssue(
          'experiences',
          l.endDateBeforeStart(label),
        );
      }
    }

    for (var i = 0; i < cv.educations.length; i++) {
      final edu = cv.educations[i];
      final label = l.numberedItem(l.education, i + 1);
      if (_isBlank(edu.etablissement)) {
        return CvSaveValidationIssue(
          'formations',
          l.requiredFieldMessage(label, l.establishment),
        );
      }
      if (_isBlank(edu.diplome)) {
        return CvSaveValidationIssue(
          'formations',
          l.requiredFieldMessage(label, l.degree),
        );
      }
      if (edu.dateDebut == null) {
        return CvSaveValidationIssue(
          'formations',
          l.requiredFieldMessage(label, l.start),
        );
      }
      if (edu.dateFin != null && edu.dateFin!.isBefore(edu.dateDebut!)) {
        return CvSaveValidationIssue(
          'formations',
          l.endDateBeforeStart(label),
        );
      }
    }

    for (var i = 0; i < cv.skills.length; i++) {
      final skill = cv.skills[i];
      final label = l.numberedItem(l.skills, i + 1);
      if (_isBlank(skill.nom)) {
        return CvSaveValidationIssue(
          'competences',
          l.requiredFieldMessage(label, l.name),
        );
      }
      if (skill.niveau != null && (skill.niveau! < 1 || skill.niveau! > 5)) {
        return CvSaveValidationIssue(
          'competences',
          l.skillLevelRange(label),
        );
      }
    }

    for (var i = 0; i < cv.languages.length; i++) {
      final language = cv.languages[i];
      final label = l.numberedItem(l.languages, i + 1);
      if (_isBlank(language.langue)) {
        return CvSaveValidationIssue(
          'langues',
          l.requiredFieldMessage(label, l.language),
        );
      }
      if (_isBlank(language.niveau)) {
        return CvSaveValidationIssue(
          'langues',
          l.requiredFieldMessage(label, l.level),
        );
      }
    }

    for (var i = 0; i < cv.certifications.length; i++) {
      final cert = cv.certifications[i];
      if (_isBlank(cert.nom)) {
        return CvSaveValidationIssue(
          'certifications',
          l.requiredFieldMessage(
              l.numberedItem(l.certifications, i + 1), l.name),
        );
      }
      if (cert.dateExpiration != null &&
          cert.dateObtention != null &&
          cert.dateExpiration!.isBefore(cert.dateObtention!)) {
        return CvSaveValidationIssue(
          'certifications',
          l.certificationExpirationBeforeIssue(
              l.numberedItem(l.certifications, i + 1)),
        );
      }
    }

    for (var i = 0; i < cv.projects.length; i++) {
      final project = cv.projects[i];
      final label = l.numberedItem(l.projects, i + 1);
      if (_isBlank(project.nom)) {
        return CvSaveValidationIssue(
          'projets',
          l.requiredFieldMessage(label, l.name),
        );
      }
      if (project.dateFin != null &&
          project.dateDebut != null &&
          project.dateFin!.isBefore(project.dateDebut!)) {
        return CvSaveValidationIssue(
          'projets',
          l.endDateBeforeStart(label),
        );
      }
    }

    return null;
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  void _validatePersonalInfo(
      PersonalInfo? info, List<ValidationIssue> w, List<ValidationIssue> e,
      AppLocalizations l) {
    if (info == null) {
      e.add(ValidationIssue('identite', l.validationPersonalInfoMissing));
      return;
    }

    if (info.prenom == null || info.prenom!.isEmpty) {
      e.add(ValidationIssue('identite', l.validationFieldMissing(l.firstName)));
    }
    if (info.nom == null || info.nom!.isEmpty) {
      e.add(ValidationIssue('identite', l.validationFieldMissing(l.lastName)));
    }
    if (info.email == null || info.email!.isEmpty) {
      e.add(ValidationIssue('identite', l.validationFieldMissing(l.emailShort)));
    }
    if (info.titrePoste == null || info.titrePoste!.isEmpty) {
      w.add(ValidationIssue('identite', l.validationJobTitleMissing));
    }

    // Resume
    final resume = info.resumeProfessionnel ?? '';
    if (resume.isEmpty) {
      w.add(ValidationIssue('profil', l.validationSummaryEmpty));
    } else if (resume.length < 100) {
      w.add(ValidationIssue('profil', l.validationSummaryShort(resume.length)));
    }

    // LinkedIn/GitHub pour les devs
    if (info.titrePoste != null) {
      final titre = info.titrePoste!.toLowerCase();
      if (titre.contains('dev') ||
          titre.contains('ingenieur') ||
          titre.contains('ingénieur')) {
        if ((info.linkedIn == null || info.linkedIn!.isEmpty) &&
            (info.portfolio == null || info.portfolio!.isEmpty)) {
          w.add(ValidationIssue('identite', l.validationTechLinkMissing));
        }
      }
    }
  }

  void _validateExperiences(
      List<Experience> exps, List<ValidationIssue> w, List<ValidationIssue> e,
      AppLocalizations l) {
    if (exps.isEmpty) {
      w.add(ValidationIssue('experiences', l.validationNoExperience));
      return;
    }

    final now = DateTime.now();
    for (int i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final label = l.numberedItem(l.experiences, i + 1);

      // Description vide
      if (exp.description == null || exp.description!.trim().isEmpty) {
        e.add(ValidationIssue(
            'experiences', l.validationDescriptionMissing(label)));
      } else {
        // Pas de chiffre dans la description
        if (!RegExp(r'\d').hasMatch(exp.description!)) {
          w.add(ValidationIssue('experiences', l.validationNoMetric(label)));
        }
      }

      // Dates
      if (exp.dateDebut != null && exp.dateFin != null) {
        if (exp.dateFin!.isBefore(exp.dateDebut!)) {
          e.add(ValidationIssue(
              'experiences', l.validationEndBeforeStart(label)));
        }
      }
      if (exp.dateFin != null &&
          exp.dateFin!.isAfter(now.add(const Duration(days: 30)))) {
        w.add(ValidationIssue('experiences', l.validationFutureEnd(label)));
      }
    }
  }

  void _validateEducations(List<Education> edus, List<ValidationIssue> w,
      AppLocalizations l) {
    if (edus.isEmpty) {
      w.add(ValidationIssue('formations', l.validationNoEducation));
    }
  }

  void _validateSkills(
      List<Skill> skills, List<ValidationIssue> w, AppLocalizations l) {
    if (skills.isEmpty) {
      w.add(ValidationIssue('competences', l.validationNoSkills));
    } else if (skills.length < 5) {
      w.add(ValidationIssue(
          'competences', l.validationFewSkills(skills.length)));
    }

    // Detecter les competences en bloc
    for (final s in skills) {
      if (s.nom != null && s.nom!.contains(',')) {
        w.add(ValidationIssue(
            'competences', l.validationCombinedSkills(s.nom!)));
      }
    }
  }

  void _validateLanguages(
      List<Language> langs, List<ValidationIssue> w, AppLocalizations l) {
    if (langs.isEmpty) {
      w.add(ValidationIssue('langues', l.validationNoLanguages));
    }
  }

  void _validateCertifications(
      List<Certification> certs, List<ValidationIssue> w,
      AppLocalizations l) {
    final now = DateTime.now();
    for (final cert in certs) {
      if (cert.dateObtention != null && cert.dateObtention!.isAfter(now)) {
        w.add(ValidationIssue('certifications',
            l.validationFutureCertification(cert.nom ?? '')));
      }
    }
  }

  void _validateProjects(
      List<Project> projects, List<ValidationIssue> w, AppLocalizations l) {
    for (final p in projects) {
      if (p.description == null || p.description!.length < 30) {
        w.add(ValidationIssue(
            'projets', l.validationShortProject(p.nom ?? '')));
      }
    }
  }

  void _validateOverall(
      Cv cv, List<ValidationIssue> w, AppLocalizations l) {
    // Trop de contenu pour 1 page
    final totalItems = cv.experiences.length +
        cv.educations.length +
        cv.skills.length +
        cv.certifications.length +
        cv.projects.length;
    if (totalItems > 25) {
      w.add(ValidationIssue(
          'general', l.validationTooMuchContent(totalItems)));
    }
  }
}

class ValidationReport {
  final int score;
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;

  const ValidationReport({
    required this.score,
    required this.errors,
    required this.warnings,
  });

  bool get canExport => score >= CvValidationThresholds.exportThreshold;
  int get totalIssues => errors.length + warnings.length;
}

class ValidationIssue {
  final String category;
  final String message;

  const ValidationIssue(this.category, this.message);
}

class CvSaveValidationIssue {
  final String category;
  final String message;

  const CvSaveValidationIssue(this.category, this.message);
}
