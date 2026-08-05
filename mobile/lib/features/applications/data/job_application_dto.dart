import '../domain/job_application.dart';
import '../domain/job_application_status.dart';

/// (De)serialisation JSON des candidatures (issue #246, A2).
///
/// Isole le format transport de l'entite de domaine [JobApplication], qui reste
/// Dart pur. Reproduit le contrat de l'ancien `JobApplication.fromJson/toJson`.
abstract final class JobApplicationDto {
  static JobApplication fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as int?,
        cvId: json['cvId'] as int?,
        cvTitle: json['cvTitle'] as String?,
        cvVariant: json['cvVariant'] as bool? ?? false,
        company: json['company'] as String,
        position: json['position'] as String,
        offerUrl: json['offerUrl'] as String?,
        status: JobApplicationStatus.fromApi(json['status'] as String),
        sentDate: _date(json['sentDate']),
        nextFollowUp: _date(json['nextFollowUp']),
        notes: json['notes'] as String?,
      );

  static Map<String, dynamic> toJson(JobApplication a) => {
        'cvId': a.cvId,
        'company': a.company,
        'position': a.position,
        'offerUrl': a.offerUrl,
        'status': a.status.apiValue,
        'sentDate': formatDate(a.sentDate),
        'nextFollowUp': formatDate(a.nextFollowUp),
        'notes': a.notes,
      };

  static DateTime? _date(dynamic value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  /// Format `YYYY-MM-DD` attendu par l'API.
  static String? formatDate(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
}
