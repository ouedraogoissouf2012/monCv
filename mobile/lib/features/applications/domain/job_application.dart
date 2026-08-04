import 'job_application_status.dart';

/// Candidature a une offre d'emploi (issue #246).
///
/// Entite de domaine : Dart pur, sans Flutter, HTTP ni JSON. Immuable.
class JobApplication {
  final int? id;
  final int? cvId;
  final String? cvTitle;
  final bool cvVariant;
  final String company;
  final String position;
  final String? offerUrl;
  final JobApplicationStatus status;
  final DateTime? sentDate;
  final DateTime? nextFollowUp;
  final String? notes;

  const JobApplication({
    this.id,
    this.cvId,
    this.cvTitle,
    this.cvVariant = false,
    required this.company,
    required this.position,
    this.offerUrl,
    this.status = JobApplicationStatus.draft,
    this.sentDate,
    this.nextFollowUp,
    this.notes,
  });

  /// Une relance est due si une date de suivi est passee (au jour pres) et que
  /// le statut n'est pas termine.
  ///
  /// L'horloge est INJECTEE ([now]) : le domaine ne lit jamais `DateTime.now()`
  /// (issue #246, follow-up testable et deterministe).
  bool isFollowUpDue(DateTime now) {
    final due = nextFollowUp;
    if (due == null || status.isClosed) return false;
    // Comparaison au jour pres : une relance datee d'aujourd'hui est due, quelle
    // que soit l'heure (les deux bornes sont tronquees a minuit).
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return !dueDay.isAfter(today);
  }

  JobApplication copyWith({
    int? id,
    int? cvId,
    String? cvTitle,
    bool? cvVariant,
    String? company,
    String? position,
    String? offerUrl,
    JobApplicationStatus? status,
    DateTime? sentDate,
    DateTime? nextFollowUp,
    String? notes,
  }) =>
      JobApplication(
        id: id ?? this.id,
        cvId: cvId ?? this.cvId,
        cvTitle: cvTitle ?? this.cvTitle,
        cvVariant: cvVariant ?? this.cvVariant,
        company: company ?? this.company,
        position: position ?? this.position,
        offerUrl: offerUrl ?? this.offerUrl,
        status: status ?? this.status,
        sentDate: sentDate ?? this.sentDate,
        nextFollowUp: nextFollowUp ?? this.nextFollowUp,
        notes: notes ?? this.notes,
      );
}
