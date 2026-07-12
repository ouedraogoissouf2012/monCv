import '../models/cv.dart';

/// Service de validation intelligente du CV.
/// Detecte les incoherences, champs manquants, et problemes de credibilite.
class CvValidator {
  static final CvValidator _instance = CvValidator._();
  CvValidator._();
  factory CvValidator() => _instance;

  /// Valide un CV complet et retourne un rapport.
  ValidationReport validate(Cv cv) {
    final warnings = <ValidationIssue>[];
    final errors = <ValidationIssue>[];

    _validatePersonalInfo(cv.personalInfo, warnings, errors);
    _validateExperiences(cv.experiences, warnings, errors);
    _validateEducations(cv.educations, warnings);
    _validateSkills(cv.skills, warnings);
    _validateLanguages(cv.languages, warnings);
    _validateCertifications(cv.certifications, warnings);
    _validateProjects(cv.projects, warnings);
    _validateOverall(cv, warnings);

    // Calcul du score
    const maxScore = 100;
    final deductions = errors.length * 15 + warnings.length * 5;
    final score = (maxScore - deductions).clamp(0, 100);

    return ValidationReport(
      score: score,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Retourne la premiere erreur bloquante avant l'envoi au backend.
  /// Cette validation est alignee sur les contraintes de CvRequest cote API.
  CvSaveValidationIssue? validateForSave(Cv cv) {
    if (_isBlank(cv.titre)) {
      return const CvSaveValidationIssue(
        'identite',
        'Titre du CV obligatoire.',
      );
    }

    final info = cv.personalInfo;
    if (info == null) {
      return const CvSaveValidationIssue(
        'identite',
        'Identite : completez vos informations personnelles.',
      );
    }
    if (_isBlank(info.prenom)) {
      return const CvSaveValidationIssue(
        'identite',
        'Identite : prenom obligatoire.',
      );
    }
    if (_isBlank(info.nom)) {
      return const CvSaveValidationIssue(
        'identite',
        'Identite : nom obligatoire.',
      );
    }
    if (_isBlank(info.email)) {
      return const CvSaveValidationIssue(
        'identite',
        'Identite : email obligatoire.',
      );
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
        .hasMatch(info.email!.trim())) {
      return const CvSaveValidationIssue(
        'identite',
        'Identite : format email invalide.',
      );
    }

    for (var i = 0; i < cv.experiences.length; i++) {
      final exp = cv.experiences[i];
      final label = 'Experience ${i + 1}';
      if (_isBlank(exp.poste)) {
        return CvSaveValidationIssue(
          'experiences',
          '$label : intitule du poste obligatoire.',
        );
      }
      if (_isBlank(exp.entreprise)) {
        return CvSaveValidationIssue(
          'experiences',
          '$label : entreprise obligatoire.',
        );
      }
      if (exp.dateDebut == null) {
        return CvSaveValidationIssue(
          'experiences',
          '$label : date de debut obligatoire.',
        );
      }
      if (exp.dateFin != null && exp.dateFin!.isBefore(exp.dateDebut!)) {
        return CvSaveValidationIssue(
          'experiences',
          '$label : la date de fin doit etre apres la date de debut.',
        );
      }
    }

    for (var i = 0; i < cv.educations.length; i++) {
      final edu = cv.educations[i];
      final label = 'Formation ${i + 1}';
      if (_isBlank(edu.etablissement)) {
        return CvSaveValidationIssue(
          'formations',
          '$label : etablissement obligatoire.',
        );
      }
      if (_isBlank(edu.diplome)) {
        return CvSaveValidationIssue(
          'formations',
          '$label : diplome obligatoire.',
        );
      }
      if (edu.dateDebut == null) {
        return CvSaveValidationIssue(
          'formations',
          '$label : date de debut obligatoire.',
        );
      }
      if (edu.dateFin != null && edu.dateFin!.isBefore(edu.dateDebut!)) {
        return CvSaveValidationIssue(
          'formations',
          '$label : la date de fin doit etre apres la date de debut.',
        );
      }
    }

    for (var i = 0; i < cv.skills.length; i++) {
      final skill = cv.skills[i];
      final label = 'Competence ${i + 1}';
      if (_isBlank(skill.nom)) {
        return CvSaveValidationIssue(
          'competences',
          '$label : nom obligatoire.',
        );
      }
      if (skill.niveau != null && (skill.niveau! < 1 || skill.niveau! > 5)) {
        return CvSaveValidationIssue(
          'competences',
          '$label : le niveau doit etre entre 1 et 5.',
        );
      }
    }

    for (var i = 0; i < cv.languages.length; i++) {
      final language = cv.languages[i];
      final label = 'Langue ${i + 1}';
      if (_isBlank(language.langue)) {
        return CvSaveValidationIssue(
          'langues',
          '$label : langue obligatoire.',
        );
      }
      if (_isBlank(language.niveau)) {
        return CvSaveValidationIssue(
          'langues',
          '$label : niveau obligatoire.',
        );
      }
    }

    for (var i = 0; i < cv.certifications.length; i++) {
      final cert = cv.certifications[i];
      if (_isBlank(cert.nom)) {
        return CvSaveValidationIssue(
          'certifications',
          'Certification ${i + 1} : nom obligatoire.',
        );
      }
      if (cert.dateExpiration != null &&
          cert.dateObtention != null &&
          cert.dateExpiration!.isBefore(cert.dateObtention!)) {
        return CvSaveValidationIssue(
          'certifications',
          'Certification ${i + 1} : expiration avant obtention.',
        );
      }
    }

    for (var i = 0; i < cv.projects.length; i++) {
      final project = cv.projects[i];
      final label = 'Projet ${i + 1}';
      if (_isBlank(project.nom)) {
        return CvSaveValidationIssue(
          'projets',
          '$label : nom obligatoire.',
        );
      }
      if (project.dateFin != null &&
          project.dateDebut != null &&
          project.dateFin!.isBefore(project.dateDebut!)) {
        return CvSaveValidationIssue(
          'projets',
          '$label : la date de fin doit etre apres la date de debut.',
        );
      }
    }

    return null;
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  void _validatePersonalInfo(
      PersonalInfo? info, List<ValidationIssue> w, List<ValidationIssue> e) {
    if (info == null) {
      e.add(const ValidationIssue(
          'identite', 'Informations personnelles manquantes'));
      return;
    }

    if (info.prenom == null || info.prenom!.isEmpty) {
      e.add(const ValidationIssue('identite', 'Prénom manquant'));
    }
    if (info.nom == null || info.nom!.isEmpty) {
      e.add(const ValidationIssue('identite', 'Nom manquant'));
    }
    if (info.email == null || info.email!.isEmpty) {
      e.add(const ValidationIssue('identite', 'Email manquant'));
    }
    if (info.titrePoste == null || info.titrePoste!.isEmpty) {
      w.add(const ValidationIssue('identite',
          'Titre du poste manquant — important pour les recruteurs'));
    }

    // Resume
    final resume = info.resumeProfessionnel ?? '';
    if (resume.isEmpty) {
      w.add(const ValidationIssue('profil',
          'Résumé professionnel vide — utilisez l\'IA pour le générer'));
    } else if (resume.length < 100) {
      w.add(ValidationIssue('profil',
          'Résumé trop court (${resume.length} car.) — min 100 recommandé'));
    }

    // LinkedIn/GitHub pour les devs
    if (info.titrePoste != null) {
      final titre = info.titrePoste!.toLowerCase();
      if (titre.contains('dev') ||
          titre.contains('ingenieur') ||
          titre.contains('ingénieur')) {
        if ((info.linkedIn == null || info.linkedIn!.isEmpty) &&
            (info.portfolio == null || info.portfolio!.isEmpty)) {
          w.add(const ValidationIssue('identite',
              'LinkedIn ou GitHub manquant — très attendu pour un profil tech'));
        }
      }
    }
  }

  void _validateExperiences(
      List<Experience> exps, List<ValidationIssue> w, List<ValidationIssue> e) {
    if (exps.isEmpty) {
      w.add(
          const ValidationIssue('experiences', 'Aucune expérience renseignée'));
      return;
    }

    final now = DateTime.now();
    for (int i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final label = 'Exp. ${i + 1}';

      // Description vide
      if (exp.description == null || exp.description!.trim().isEmpty) {
        e.add(ValidationIssue('experiences', '$label: description manquante'));
      } else {
        // Pas de chiffre dans la description
        if (!RegExp(r'\d').hasMatch(exp.description!)) {
          w.add(ValidationIssue('experiences',
              '$label: aucun chiffre/métrique — ajoutez des résultats mesurables'));
        }
      }

      // Dates
      if (exp.dateDebut != null && exp.dateFin != null) {
        if (exp.dateFin!.isBefore(exp.dateDebut!)) {
          e.add(ValidationIssue(
              'experiences', '$label: date de fin avant date de début'));
        }
      }
      if (exp.dateFin != null &&
          exp.dateFin!.isAfter(now.add(const Duration(days: 30)))) {
        w.add(ValidationIssue(
            'experiences', '$label: date de fin dans le futur'));
      }
    }
  }

  void _validateEducations(List<Education> edus, List<ValidationIssue> w) {
    if (edus.isEmpty) {
      w.add(const ValidationIssue('formations', 'Aucune formation renseignée'));
    }
  }

  void _validateSkills(List<Skill> skills, List<ValidationIssue> w) {
    if (skills.isEmpty) {
      w.add(
          const ValidationIssue('competences', 'Aucune compétence renseignée'));
    } else if (skills.length < 5) {
      w.add(ValidationIssue('competences',
          'Seulement ${skills.length} compétences — 8 à 12 recommandé'));
    }

    // Detecter les competences en bloc
    for (final s in skills) {
      if (s.nom != null && s.nom!.contains(',')) {
        w.add(ValidationIssue('competences',
            '"${s.nom}" semble contenir plusieurs compétences — séparez-les'));
      }
    }
  }

  void _validateLanguages(List<Language> langs, List<ValidationIssue> w) {
    if (langs.isEmpty) {
      w.add(const ValidationIssue('langues', 'Aucune langue renseignée'));
    }
  }

  void _validateCertifications(
      List<Certification> certs, List<ValidationIssue> w) {
    final now = DateTime.now();
    for (final cert in certs) {
      if (cert.dateObtention != null && cert.dateObtention!.isAfter(now)) {
        w.add(ValidationIssue('certifications',
            '"${cert.nom}" datée dans le futur — marquez "En cours" si pas encore obtenue'));
      }
    }
  }

  void _validateProjects(List<Project> projects, List<ValidationIssue> w) {
    for (final p in projects) {
      if (p.description == null || p.description!.length < 30) {
        w.add(ValidationIssue(
            'projets', '"${p.nom}" : description trop courte — développez'));
      }
    }
  }

  void _validateOverall(Cv cv, List<ValidationIssue> w) {
    // Trop de contenu pour 1 page
    final totalItems = cv.experiences.length +
        cv.educations.length +
        cv.skills.length +
        cv.certifications.length +
        cv.projects.length;
    if (totalItems > 25) {
      w.add(ValidationIssue('general',
          'Beaucoup de contenu ($totalItems éléments) — risque de dépasser 1 page'));
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

  bool get canExport => score >= 60;
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
