import '../../../../../models/cv.dart';
import '../../policies/cv_validation_thresholds.dart';
import '../cv_validation_rule.dart';
import '../validation_code.dart';
import '../validation_result.dart';

bool _blankText(String? v) => v == null || v.trim().isEmpty;

/// Regles de qualite sur les experiences (issue #241).
class ExperienceRule implements CvValidationRule {
  const ExperienceRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final exps = cv.experiences;
    if (exps.isEmpty) {
      return [
        ValidationMessage.warning('experiences', ValidationCode.noExperience),
      ];
    }

    final out = <ValidationMessage>[];
    final now = DateTime.now();
    final futureLimit = now.add(
        const Duration(days: CvValidationThresholds.futureDateToleranceDays));

    for (var i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final params = {'index': i + 1};

      if (_blankText(exp.description)) {
        out.add(ValidationMessage.error(
            'experiences', ValidationCode.descriptionMissing,
            params: params));
      } else if (!RegExp(r'\d').hasMatch(exp.description!)) {
        out.add(ValidationMessage.warning(
            'experiences', ValidationCode.noMetric,
            params: params));
      }

      if (exp.dateDebut != null &&
          exp.dateFin != null &&
          exp.dateFin!.isBefore(exp.dateDebut!)) {
        out.add(ValidationMessage.error(
            'experiences', ValidationCode.endBeforeStart,
            params: params));
      }
      if (exp.dateFin != null && exp.dateFin!.isAfter(futureLimit)) {
        out.add(ValidationMessage.warning(
            'experiences', ValidationCode.futureEnd,
            params: params));
      }
    }
    return out;
  }
}

/// Regle de qualite sur les formations (issue #241).
class EducationRule implements CvValidationRule {
  const EducationRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) => cv.educations.isEmpty
      ? [ValidationMessage.warning('formations', ValidationCode.noEducation)]
      : const [];
}

/// Regles de qualite sur les competences (issue #241).
class SkillsRule implements CvValidationRule {
  const SkillsRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final skills = cv.skills;
    final out = <ValidationMessage>[];

    if (skills.isEmpty) {
      out.add(ValidationMessage.warning(
          'competences', ValidationCode.noSkills));
    } else if (skills.length < CvValidationThresholds.recommendedSkillCount) {
      out.add(ValidationMessage.warning(
          'competences', ValidationCode.fewSkills,
          params: {'count': skills.length}));
    }

    for (final s in skills) {
      if (s.nom != null && s.nom!.contains(',')) {
        out.add(ValidationMessage.warning(
            'competences', ValidationCode.combinedSkills,
            params: {'name': s.nom!}));
      }
    }
    return out;
  }
}

/// Regle de qualite sur les langues (issue #241).
class LanguagesRule implements CvValidationRule {
  const LanguagesRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) => cv.languages.isEmpty
      ? [ValidationMessage.warning('langues', ValidationCode.noLanguages)]
      : const [];
}

/// Regle de qualite sur les certifications (issue #241).
class CertificationsRule implements CvValidationRule {
  const CertificationsRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final now = DateTime.now();
    final out = <ValidationMessage>[];
    for (final cert in cv.certifications) {
      if (cert.dateObtention != null && cert.dateObtention!.isAfter(now)) {
        out.add(ValidationMessage.warning(
            'certifications', ValidationCode.futureCertification,
            params: {'name': cert.nom ?? ''}));
      }
    }
    return out;
  }
}

/// Regle de qualite sur les projets (issue #241).
class ProjectsRule implements CvValidationRule {
  const ProjectsRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final out = <ValidationMessage>[];
    for (final p in cv.projects) {
      final len = p.description?.length ?? 0;
      if (len < CvValidationThresholds.minProjectDescriptionLength) {
        out.add(ValidationMessage.warning(
            'projets', ValidationCode.shortProject,
            params: {'name': p.nom ?? ''}));
      }
    }
    return out;
  }
}

/// Regle globale : trop de contenu pour une page (issue #241).
class OverallContentRule implements CvValidationRule {
  const OverallContentRule();

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final total = cv.experiences.length +
        cv.educations.length +
        cv.skills.length +
        cv.certifications.length +
        cv.projects.length;
    if (total > CvValidationThresholds.maxItemsBeforeOverflow) {
      return [
        ValidationMessage.warning('general', ValidationCode.tooMuchContent,
            params: {'count': total}),
      ];
    }
    return const [];
  }
}
