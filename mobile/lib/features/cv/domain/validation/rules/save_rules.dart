import '../../../../../features/cv/presentation/cv_presentation_model.dart';
import '../cv_validation_rule.dart';
import '../validation_code.dart';
import '../validation_result.dart';

/// Regles de validation BLOQUANTES avant sauvegarde (issue #241).
///
/// Reproduit exactement `CvValidator.validateForSave` : produit des messages
/// `error` dans un ordre deterministe. Le premier `error` (via
/// `ValidationOutcome.firstError`) correspond a l'ancien retour `first-error`.
/// Pure : ne produit que des [ValidationCode] + params.
class CvSaveRules implements CvValidationRule {
  const CvSaveRules();

  static bool _blank(String? v) => v == null || v.trim().isEmpty;

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final out = <ValidationMessage>[];

    // Titre du CV
    if (_blank(cv.titre)) {
      out.add(ValidationMessage.error('identite', ValidationCode.cvTitleRequired));
    }

    // Identite
    final info = cv.personalInfo;
    if (info == null) {
      out.add(ValidationMessage.error(
          'identite', ValidationCode.personalInfoIncomplete));
    } else {
      if (_blank(info.prenom)) {
        out.add(_field('identite', 'firstName'));
      }
      if (_blank(info.nom)) out.add(_field('identite', 'lastName'));
      if (_blank(info.email)) {
        out.add(_field('identite', 'email'));
      } else if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
          .hasMatch(info.email!.trim())) {
        out.add(ValidationMessage.error(
            'identite', ValidationCode.invalidEmail));
      }
    }

    _experiences(cv, out);
    _educations(cv, out);
    _skills(cv, out);
    _languages(cv, out);
    _certifications(cv, out);
    _projects(cv, out);

    return out;
  }

  ValidationMessage _field(String section, String field) =>
      ValidationMessage.error(section, ValidationCode.requiredFieldMissing,
          params: {'field': field});

  ValidationMessage _itemField(String section, int index, String field) =>
      ValidationMessage.error(section, ValidationCode.requiredFieldMissing,
          params: {'itemSection': section, 'index': index, 'field': field});

  void _experiences(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.experiences.length; i++) {
      final e = cv.experiences[i];
      if (_blank(e.poste)) out.add(_itemField('experiences', i + 1, 'jobTitle'));
      if (_blank(e.entreprise)) {
        out.add(_itemField('experiences', i + 1, 'company'));
      }
      if (e.dateDebut == null) {
        out.add(_itemField('experiences', i + 1, 'start'));
      }
      if (e.dateFin != null && e.dateDebut != null &&
          e.dateFin!.isBefore(e.dateDebut!)) {
        out.add(ValidationMessage.error(
            'experiences', ValidationCode.endBeforeStart,
            params: {'index': i + 1, 'itemSection': 'experiences'}));
      }
    }
  }

  void _educations(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.educations.length; i++) {
      final edu = cv.educations[i];
      if (_blank(edu.etablissement)) {
        out.add(_itemField('education', i + 1, 'establishment'));
      }
      if (_blank(edu.diplome)) out.add(_itemField('education', i + 1, 'degree'));
      if (edu.dateDebut == null) {
        out.add(_itemField('education', i + 1, 'start'));
      }
      if (edu.dateFin != null && edu.dateDebut != null &&
          edu.dateFin!.isBefore(edu.dateDebut!)) {
        out.add(ValidationMessage.error('formations',
            ValidationCode.endBeforeStart,
            params: {'index': i + 1, 'itemSection': 'education'}));
      }
    }
  }

  void _skills(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.skills.length; i++) {
      final s = cv.skills[i];
      if (_blank(s.nom)) out.add(_itemField('skills', i + 1, 'name'));
      if (s.niveau != null && (s.niveau! < 1 || s.niveau! > 5)) {
        out.add(ValidationMessage.error(
            'competences', ValidationCode.skillLevelOutOfRange,
            params: {'index': i + 1, 'itemSection': 'skills'}));
      }
    }
  }

  void _languages(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.languages.length; i++) {
      final lg = cv.languages[i];
      if (_blank(lg.langue)) out.add(_itemField('languages', i + 1, 'language'));
      if (_blank(lg.niveau)) out.add(_itemField('languages', i + 1, 'level'));
    }
  }

  void _certifications(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.certifications.length; i++) {
      final c = cv.certifications[i];
      if (_blank(c.nom)) out.add(_itemField('certifications', i + 1, 'name'));
      if (c.dateExpiration != null && c.dateObtention != null &&
          c.dateExpiration!.isBefore(c.dateObtention!)) {
        out.add(ValidationMessage.error('certifications',
            ValidationCode.certificationExpirationBeforeIssue,
            params: {'index': i + 1, 'itemSection': 'certifications'}));
      }
    }
  }

  void _projects(Cv cv, List<ValidationMessage> out) {
    for (var i = 0; i < cv.projects.length; i++) {
      final p = cv.projects[i];
      if (_blank(p.nom)) out.add(_itemField('projets', i + 1, 'name'));
      if (p.dateFin != null && p.dateDebut != null &&
          p.dateFin!.isBefore(p.dateDebut!)) {
        out.add(ValidationMessage.error('projets', ValidationCode.endBeforeStart,
            params: {'index': i + 1, 'itemSection': 'projets'}));
      }
    }
  }
}
