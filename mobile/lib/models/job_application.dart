enum JobApplicationStatus {
  draft,
  sent,
  interview,
  technicalTest,
  offer,
  rejected,
  archived;

  String get apiValue => switch (this) {
        draft => 'DRAFT',
        sent => 'SENT',
        interview => 'INTERVIEW',
        technicalTest => 'TECHNICAL_TEST',
        offer => 'OFFER',
        rejected => 'REJECTED',
        archived => 'ARCHIVED',
      };

  static JobApplicationStatus fromApi(String value) => switch (value) {
        'SENT' => sent,
        'INTERVIEW' => interview,
        'TECHNICAL_TEST' => technicalTest,
        'OFFER' => offer,
        'REJECTED' => rejected,
        'ARCHIVED' => archived,
        _ => draft,
      };
}

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

  bool get followUpDue {
    if (nextFollowUp == null ||
        status == JobApplicationStatus.offer ||
        status == JobApplicationStatus.rejected ||
        status == JobApplicationStatus.archived) {
      return false;
    }
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    return !nextFollowUp!.isAfter(date);
  }

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
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

  Map<String, dynamic> toJson() => {
        'cvId': cvId,
        'company': company,
        'position': position,
        'offerUrl': offerUrl,
        'status': status.apiValue,
        'sentDate': formatDate(sentDate),
        'nextFollowUp': formatDate(nextFollowUp),
        'notes': notes,
      };

  static DateTime? _date(dynamic value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  static String? formatDate(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
