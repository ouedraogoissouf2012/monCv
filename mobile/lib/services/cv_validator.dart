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
    final maxScore = 100;
    final deductions = errors.length * 15 + warnings.length * 5;
    final score = (maxScore - deductions).clamp(0, 100);

    return ValidationReport(
      score: score,
      errors: errors,
      warnings: warnings,
    );
  }

  void _validatePersonalInfo(PersonalInfo? info, List<ValidationIssue> w, List<ValidationIssue> e) {
    if (info == null) {
      e.add(ValidationIssue('identite', 'Informations personnelles manquantes'));
      return;
    }

    if (info.prenom == null || info.prenom!.isEmpty) {
      e.add(ValidationIssue('identite', 'Prénom manquant'));
    }
    if (info.nom == null || info.nom!.isEmpty) {
      e.add(ValidationIssue('identite', 'Nom manquant'));
    }
    if (info.email == null || info.email!.isEmpty) {
      e.add(ValidationIssue('identite', 'Email manquant'));
    }
    if (info.titrePoste == null || info.titrePoste!.isEmpty) {
      w.add(ValidationIssue('identite', 'Titre du poste manquant — important pour les recruteurs'));
    }

    // Resume
    final resume = info.resumeProfessionnel ?? '';
    if (resume.isEmpty) {
      w.add(ValidationIssue('profil', 'Résumé professionnel vide — utilisez l\'IA pour le générer'));
    } else if (resume.length < 100) {
      w.add(ValidationIssue('profil', 'Résumé trop court (${resume.length} car.) — min 100 recommandé'));
    }

    // LinkedIn/GitHub pour les devs
    if (info.titrePoste != null) {
      final titre = info.titrePoste!.toLowerCase();
      if (titre.contains('dev') || titre.contains('ingenieur') || titre.contains('ingénieur')) {
        if ((info.linkedIn == null || info.linkedIn!.isEmpty) &&
            (info.portfolio == null || info.portfolio!.isEmpty)) {
          w.add(ValidationIssue('identite', 'LinkedIn ou GitHub manquant — très attendu pour un profil tech'));
        }
      }
    }
  }

  void _validateExperiences(List<Experience> exps, List<ValidationIssue> w, List<ValidationIssue> e) {
    if (exps.isEmpty) {
      w.add(ValidationIssue('experiences', 'Aucune expérience renseignée'));
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
          w.add(ValidationIssue('experiences', '$label: aucun chiffre/métrique — ajoutez des résultats mesurables'));
        }
      }

      // Dates
      if (exp.dateDebut != null && exp.dateFin != null) {
        if (exp.dateFin!.isBefore(exp.dateDebut!)) {
          e.add(ValidationIssue('experiences', '$label: date de fin avant date de début'));
        }
      }
      if (exp.dateFin != null && exp.dateFin!.isAfter(now.add(const Duration(days: 30)))) {
        w.add(ValidationIssue('experiences', '$label: date de fin dans le futur'));
      }
    }
  }

  void _validateEducations(List<Education> edus, List<ValidationIssue> w) {
    if (edus.isEmpty) {
      w.add(ValidationIssue('formations', 'Aucune formation renseignée'));
    }
  }

  void _validateSkills(List<Skill> skills, List<ValidationIssue> w) {
    if (skills.isEmpty) {
      w.add(ValidationIssue('competences', 'Aucune compétence renseignée'));
    } else if (skills.length < 5) {
      w.add(ValidationIssue('competences', 'Seulement ${skills.length} compétences — 8 à 12 recommandé'));
    }

    // Detecter les competences en bloc
    for (final s in skills) {
      if (s.nom != null && s.nom!.contains(',')) {
        w.add(ValidationIssue('competences', '"${s.nom}" semble contenir plusieurs compétences — séparez-les'));
      }
    }
  }

  void _validateLanguages(List<Language> langs, List<ValidationIssue> w) {
    if (langs.isEmpty) {
      w.add(ValidationIssue('langues', 'Aucune langue renseignée'));
    }
  }

  void _validateCertifications(List<Certification> certs, List<ValidationIssue> w) {
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
        w.add(ValidationIssue('projets', '"${p.nom}" : description trop courte — développez'));
      }
    }
  }

  void _validateOverall(Cv cv, List<ValidationIssue> w) {
    // Trop de contenu pour 1 page
    final totalItems = cv.experiences.length + cv.educations.length +
        cv.skills.length + cv.certifications.length + cv.projects.length;
    if (totalItems > 25) {
      w.add(ValidationIssue('general', 'Beaucoup de contenu ($totalItems éléments) — risque de dépasser 1 page'));
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
