import '../../domain/external_link_launcher.dart';
import '../../domain/job_application.dart';
import '../../domain/job_application_status.dart';

/// Champ d'un formulaire de candidature qui peut porter une erreur de
/// validation (issue #246, A5). Neutre : la presentation mappe [error] vers un
/// message localise.
enum ApplicationFieldError {
  /// Champ obligatoire vide.
  required,

  /// URL fournie mais invalide (schema non http/https, sans hote...).
  invalidUrl,

  /// La date de relance precede la date d'envoi.
  followUpBeforeSent,
}

/// Resultat de validation : la map des erreurs par champ. Vide => valide.
class ApplicationFormValidation {
  final Map<ApplicationFormField, ApplicationFieldError> errors;
  const ApplicationFormValidation(this.errors);

  bool get isValid => errors.isEmpty;
  ApplicationFieldError? errorFor(ApplicationFormField field) => errors[field];
}

/// Champs valides du formulaire.
enum ApplicationFormField { company, position, offerUrl, followUp }

/// Modele immuable + validation PURE d'un formulaire de candidature
/// (issue #246, A5).
///
/// Aucune dependance a Flutter : entierement testable. La validation d'URL
/// reutilise [ExternalLinkPolicy] (A3), celle des dates est portee ici.
class ApplicationFormModel {
  final int? id;
  final int? cvId;
  final String company;
  final String position;
  final String offerUrl;
  final JobApplicationStatus status;
  final DateTime? sentDate;
  final DateTime? nextFollowUp;
  final String notes;

  const ApplicationFormModel({
    this.id,
    this.cvId,
    this.company = '',
    this.position = '',
    this.offerUrl = '',
    this.status = JobApplicationStatus.draft,
    this.sentDate,
    this.nextFollowUp,
    this.notes = '',
  });

  /// Pre-remplit le formulaire depuis une candidature existante (edition).
  factory ApplicationFormModel.fromApplication(JobApplication a) =>
      ApplicationFormModel(
        id: a.id,
        cvId: a.cvId,
        company: a.company,
        position: a.position,
        offerUrl: a.offerUrl ?? '',
        status: a.status,
        sentDate: a.sentDate,
        nextFollowUp: a.nextFollowUp,
        notes: a.notes ?? '',
      );

  ApplicationFormValidation validate() {
    final errors = <ApplicationFormField, ApplicationFieldError>{};
    if (company.trim().isEmpty) {
      errors[ApplicationFormField.company] = ApplicationFieldError.required;
    }
    if (position.trim().isEmpty) {
      errors[ApplicationFormField.position] = ApplicationFieldError.required;
    }
    final url = offerUrl.trim();
    if (url.isNotEmpty && ExternalLinkPolicy.validate(url) == null) {
      errors[ApplicationFormField.offerUrl] = ApplicationFieldError.invalidUrl;
    }
    final sent = sentDate;
    final follow = nextFollowUp;
    if (sent != null && follow != null && follow.isBefore(sent)) {
      errors[ApplicationFormField.followUp] =
          ApplicationFieldError.followUpBeforeSent;
    }
    return ApplicationFormValidation(errors);
  }

  /// Construit l'entite de domaine (a n'appeler qu'apres une validation reussie).
  JobApplication toApplication() => JobApplication(
        id: id,
        cvId: cvId,
        company: company.trim(),
        position: position.trim(),
        offerUrl: offerUrl.trim().isEmpty ? null : offerUrl.trim(),
        status: status,
        sentDate: sentDate,
        nextFollowUp: nextFollowUp,
        notes: notes.trim().isEmpty ? null : notes.trim(),
      );

  ApplicationFormModel copyWith({
    int? cvId,
    bool clearCvId = false,
    String? company,
    String? position,
    String? offerUrl,
    JobApplicationStatus? status,
    DateTime? sentDate,
    bool clearSentDate = false,
    DateTime? nextFollowUp,
    bool clearFollowUp = false,
    String? notes,
  }) =>
      ApplicationFormModel(
        id: id,
        cvId: clearCvId ? null : (cvId ?? this.cvId),
        company: company ?? this.company,
        position: position ?? this.position,
        offerUrl: offerUrl ?? this.offerUrl,
        status: status ?? this.status,
        sentDate: clearSentDate ? null : (sentDate ?? this.sentDate),
        nextFollowUp:
            clearFollowUp ? null : (nextFollowUp ?? this.nextFollowUp),
        notes: notes ?? this.notes,
      );
}
