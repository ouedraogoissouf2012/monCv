import '../features/cv/domain/policies/cv_validation_thresholds.dart';
import '../models/cv.dart';

class CvReadinessIssue {
  const CvReadinessIssue(this.code, this.message, this.penalty);

  final String code;
  final String message;
  final int penalty;
}

class CvReadinessReport {
  const CvReadinessReport({required this.score, required this.issues});

  final int score;
  final List<CvReadinessIssue> issues;

  bool get isReady =>
      score >= CvValidationThresholds.readyThreshold &&
      issues.every(
          (issue) => issue.penalty < CvValidationThresholds.errorPenalty);
}

/// Evalue si un CV est exploitable par un recruteur et lisible par un ATS.
/// La sauvegarde reste autorisee afin de ne jamais perdre un brouillon.
class CvReadinessService {
  const CvReadinessService();

  static const _vagueTitles = {
    'cv',
    'curriculum vitae',
    'concours',
    'emploi',
    'candidature',
    'mon cv',
  };

  static const _cliches = {
    'motivé',
    'motivée',
    'dynamique',
    'passionné',
    'passionnée',
    'rigoureux',
    'rigoureuse',
    'sérieux',
    'sérieuse',
    'polyvalent',
    'polyvalente',
    'sens du devoir',
    'force de proposition',
  };

  CvReadinessReport evaluate(Cv cv) {
    final issues = <CvReadinessIssue>[];
    final info = cv.personalInfo;
    final title = cv.titre.trim().toLowerCase();

    if (title.isEmpty || _vagueTitles.contains(title)) {
      _add(issues, 'specific_title',
          'Remplacez le titre générique par le poste ou le concours visé.', 15);
    }
    if (_blank(info?.titrePoste)) {
      _add(issues, 'job_title', 'Ajoutez un intitulé de poste précis.', 10);
    }
    if (_blank(info?.email)) {
      _add(issues, 'email', 'Ajoutez une adresse e-mail de contact.', 15);
    }
    if (_blank(info?.telephone)) {
      _add(issues, 'phone', 'Ajoutez un numéro de téléphone.', 10);
    }

    final profile = info?.resumeProfessionnel?.trim() ?? '';
    if (profile.isEmpty) {
      _add(issues, 'profile', 'Ajoutez un résumé professionnel.', 15);
    } else {
      if (profile.length < CvValidationThresholds.minSummaryLength) {
        _add(
            issues,
            'short_profile',
            'Développez le résumé avec votre cible et une expérience concrète.',
            8);
      }
      final normalized = profile.toLowerCase();
      final clicheCount = _cliches.where(normalized.contains).length;
      if (clicheCount > CvValidationThresholds.maxTolerableCliches) {
        _add(
            issues,
            'generic_profile',
            'Remplacez les adjectifs génériques par des faits vérifiables.',
            10);
      }
      if (RegExp(r"l['’]armé(?:\s|[.,;!?]|$)", caseSensitive: false)
              .hasMatch(profile) ||
          RegExp(r'\p{L},\p{L}', unicode: true).hasMatch(profile)) {
        _add(issues, 'proofreading',
            'Corrigez les fautes et les espaces de ponctuation.', 5);
      }
    }

    if (cv.experiences.isEmpty) {
      _add(issues, 'experience', 'Ajoutez au moins une expérience.', 15);
    } else {
      final weakDescriptions = cv.experiences
          .where((experience) =>
              (experience.description?.trim().length ?? 0) <
              CvValidationThresholds.minExperienceDescriptionLength)
          .length;
      if (weakDescriptions > 0) {
        _add(
            issues,
            'experience_details',
            'Détaillez chaque expérience avec missions, outils et résultats.',
            weakDescriptions == cv.experiences.length ? 15 : 8);
      }
    }

    final suspiciousEducationDates = cv.educations.where((education) {
      final start = education.dateDebut;
      final end = education.dateFin;
      if (start == null || end == null) return false;
      final days = end.difference(start).inDays;
      return days >= 0 &&
          days < CvValidationThresholds.suspiciousEducationDurationDays;
    }).length;
    if (suspiciousEducationDates > 0) {
      _add(
          issues,
          'education_dates',
          'Vérifiez les dates de formation : une durée de quelques jours paraît incohérente.',
          suspiciousEducationDates >= 2 ? 10 : 5);
    }

    if (cv.skills.isEmpty) {
      _add(
          issues, 'skills', 'Ajoutez des compétences liées au poste visé.', 10);
    }
    if (cv.style.templateId != 'ats') {
      _add(
          issues,
          'ats_template',
          'Utilisez le modèle ATS à une colonne pour les candidatures automatisées.',
          10);
    }

    final deductions = issues.fold<int>(0, (sum, issue) => sum + issue.penalty);
    const max = CvValidationThresholds.maxScore;
    return CvReadinessReport(
      score: (max - deductions).clamp(0, max),
      issues: List.unmodifiable(issues),
    );
  }

  bool _blank(String? value) => value == null || value.trim().isEmpty;

  void _add(
    List<CvReadinessIssue> issues,
    String code,
    String message,
    int penalty,
  ) =>
      issues.add(CvReadinessIssue(code, message, penalty));
}
