import '../../../../../models/cv.dart';
import '../../policies/cv_validation_thresholds.dart';
import '../cv_validation_rule.dart';
import '../validation_code.dart';
import '../validation_result.dart';

/// Regles de qualite sur l'identite et le profil (issue #241).
///
/// Pure : produit des [ValidationCode] sans texte traduit. Reproduit
/// exactement les verifications de `CvValidator._validatePersonalInfo`.
class PersonalInfoRule implements CvValidationRule {
  const PersonalInfoRule();

  static bool _blank(String? v) => v == null || v.isEmpty;

  @override
  List<ValidationMessage> evaluate(Cv cv) {
    final info = cv.personalInfo;
    if (info == null) {
      return [
        ValidationMessage.error('identite', ValidationCode.personalInfoMissing),
      ];
    }

    final out = <ValidationMessage>[];

    if (_blank(info.prenom)) {
      out.add(ValidationMessage.error('identite',
          ValidationCode.requiredFieldMissing,
          params: const {'field': 'firstName'}));
    }
    if (_blank(info.nom)) {
      out.add(ValidationMessage.error('identite',
          ValidationCode.requiredFieldMissing,
          params: const {'field': 'lastName'}));
    }
    if (_blank(info.email)) {
      out.add(ValidationMessage.error('identite',
          ValidationCode.requiredFieldMissing,
          params: const {'field': 'email'}));
    }
    if (_blank(info.titrePoste)) {
      out.add(ValidationMessage.warning(
          'identite', ValidationCode.jobTitleMissing));
    }

    // Resume
    final resume = info.resumeProfessionnel ?? '';
    if (resume.isEmpty) {
      out.add(
          ValidationMessage.warning('profil', ValidationCode.summaryEmpty));
    } else if (resume.length < CvValidationThresholds.minSummaryLength) {
      out.add(ValidationMessage.warning('profil', ValidationCode.summaryShort,
          params: {'length': resume.length}));
    }

    // Lien tech (LinkedIn/portfolio) pour les profils dev/ingenieur
    final titre = info.titrePoste?.toLowerCase() ?? '';
    final isTech = titre.contains('dev') ||
        titre.contains('ingenieur') ||
        titre.contains('ingénieur');
    if (isTech && _blank(info.linkedIn) && _blank(info.portfolio)) {
      out.add(ValidationMessage.warning(
          'identite', ValidationCode.techLinkMissing));
    }

    return out;
  }
}
