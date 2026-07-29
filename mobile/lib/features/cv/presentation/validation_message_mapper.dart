import '../../../l10n/app_localizations.dart';
import '../domain/validation/validation_code.dart';
import '../domain/validation/validation_result.dart';

/// Traduit un [ValidationMessage] (code + params du domaine) en texte
/// localise, cote presentation (issue #241).
///
/// C'est la SEULE frontiere ou les codes de validation rencontrent
/// `AppLocalizations`. Le `switch` sur [ValidationCode] est exhaustif : le
/// compilateur refuse d'omettre un code, ce qui garantit qu'aucun code ne
/// reste sans traduction (critere #241).
class ValidationMessageMapper {
  final AppLocalizations _l;

  const ValidationMessageMapper(this._l);

  /// Libelle localise d'un [ValidationMessage].
  String message(ValidationMessage m) {
    final p = m.params;
    switch (m.code) {
      // ── Identite / profil ──────────────────────────────────
      case ValidationCode.personalInfoMissing:
        return _l.validationPersonalInfoMissing;
      case ValidationCode.requiredFieldMissing:
        return _l.validationFieldMissing(_fieldLabel(p['field'] as String?));
      case ValidationCode.jobTitleMissing:
        return _l.validationJobTitleMissing;
      case ValidationCode.invalidEmail:
        return _l.invalidEmailMessage;
      case ValidationCode.summaryEmpty:
        return _l.validationSummaryEmpty;
      case ValidationCode.summaryShort:
        return _l.validationSummaryShort(p['length'] as int? ?? 0);
      case ValidationCode.techLinkMissing:
        return _l.validationTechLinkMissing;

      // ── Experiences ────────────────────────────────────────
      case ValidationCode.noExperience:
        return _l.validationNoExperience;
      case ValidationCode.descriptionMissing:
        return _l.validationDescriptionMissing(_itemLabel(_l.experiences, p));
      case ValidationCode.noMetric:
        return _l.validationNoMetric(_itemLabel(_l.experiences, p));
      case ValidationCode.endBeforeStart:
        return _l.validationEndBeforeStart(_itemLabel(_l.experiences, p));
      case ValidationCode.futureEnd:
        return _l.validationFutureEnd(_itemLabel(_l.experiences, p));
      case ValidationCode.companyRequired:
        return _l.requiredFieldMessage(
            _itemLabel(_l.experiences, p), _l.companyRequired);
      case ValidationCode.startDateRequired:
        return _l.requiredFieldMessage(_itemLabel(_l.experiences, p), _l.start);

      // ── Formations ─────────────────────────────────────────
      case ValidationCode.noEducation:
        return _l.validationNoEducation;
      case ValidationCode.establishmentRequired:
        return _l.requiredFieldMessage(
            _itemLabel(_l.education, p), _l.establishment);
      case ValidationCode.degreeRequired:
        return _l.requiredFieldMessage(_itemLabel(_l.education, p), _l.degree);

      // ── Competences ────────────────────────────────────────
      case ValidationCode.noSkills:
        return _l.validationNoSkills;
      case ValidationCode.fewSkills:
        return _l.validationFewSkills(p['count'] as int? ?? 0);
      case ValidationCode.combinedSkills:
        return _l.validationCombinedSkills(p['name'] as String? ?? '');
      case ValidationCode.skillLevelOutOfRange:
        return _l.skillLevelRange(_itemLabel(_l.skills, p));

      // ── Langues ────────────────────────────────────────────
      case ValidationCode.noLanguages:
        return _l.validationNoLanguages;
      case ValidationCode.languageNameRequired:
        return _l.requiredFieldMessage(_itemLabel(_l.languages, p), _l.language);
      case ValidationCode.languageLevelRequired:
        return _l.requiredFieldMessage(_itemLabel(_l.languages, p), _l.level);

      // ── Certifications ─────────────────────────────────────
      case ValidationCode.futureCertification:
        return _l.validationFutureCertification(p['name'] as String? ?? '');
      case ValidationCode.certificationExpirationBeforeIssue:
        return _l.certificationExpirationBeforeIssue(
            _itemLabel(_l.certifications, p));
      case ValidationCode.certificationNameRequired:
        return _l.requiredFieldMessage(
            _itemLabel(_l.certifications, p), _l.name);

      // ── Projets ────────────────────────────────────────────
      case ValidationCode.shortProject:
        return _l.validationShortProject(p['name'] as String? ?? '');
      case ValidationCode.projectNameRequired:
        return _l.requiredFieldMessage(_itemLabel(_l.projects, p), _l.name);

      // ── Global ─────────────────────────────────────────────
      case ValidationCode.tooMuchContent:
        return _l.validationTooMuchContent(p['count'] as int? ?? 0);
    }
  }

  /// Libelle numerote d'un item (ex. "Experience 1") a partir de `index`.
  String _itemLabel(String section, Map<String, Object> p) =>
      _l.numberedItem(section, p['index'] as int? ?? 1);

  /// Traduit une cle de champ ('firstName'...) en libelle localise.
  String _fieldLabel(String? field) {
    switch (field) {
      case 'firstName':
        return _l.firstName;
      case 'lastName':
        return _l.lastName;
      case 'email':
        return _l.emailShort;
      default:
        return field ?? '';
    }
  }
}
