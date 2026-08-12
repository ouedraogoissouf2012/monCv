import '../entities/cv.dart';
import 'cv_validation_rule.dart';
import 'rules/personal_info_rules.dart';
import 'rules/section_rules.dart';
import 'validation_result.dart';

/// Registre ordonne et deterministe des regles de qualite CV (issue #241).
///
/// Compose les regles pures par section et les evalue TOUJOURS dans le meme
/// ordre, produisant un [ValidationOutcome] reproductible. Aucune dependance
/// UI : ce registre reste dans le domaine.
class CvValidationRules {
  final List<CvValidationRule> _rules;

  /// Ordre par defaut, aligne sur l'ancien `CvValidator.validate` :
  /// identite/profil -> experiences -> formations -> competences -> langues
  /// -> certifications -> projets -> global.
  const CvValidationRules()
      : _rules = const [
          PersonalInfoRule(),
          ExperienceRule(),
          EducationRule(),
          SkillsRule(),
          LanguagesRule(),
          CertificationsRule(),
          ProjectsRule(),
          OverallContentRule(),
        ];

  /// Constructeur de test : injecter un jeu de regles arbitraire.
  const CvValidationRules.withRules(List<CvValidationRule> rules)
      : _rules = rules;

  /// Evalue toutes les regles et agrege les messages dans l'ordre.
  ValidationOutcome evaluate(CvEntity cv) {
    final messages = <ValidationMessage>[];
    for (final rule in _rules) {
      messages.addAll(rule.evaluate(cv));
    }
    return ValidationOutcome(messages);
  }
}
