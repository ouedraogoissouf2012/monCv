/// Statut d'une candidature (issue #246).
///
/// Domaine pur : les libelles/couleurs/icones ne vivent PAS ici (presentation
/// localise-agnostique). Seule la correspondance avec la valeur API est portee,
/// car elle appartient au contrat metier.
enum JobApplicationStatus {
  draft,
  sent,
  interview,
  technicalTest,
  offer,
  rejected,
  archived;

  /// Valeur echangee avec l'API.
  String get apiValue => switch (this) {
        draft => 'DRAFT',
        sent => 'SENT',
        interview => 'INTERVIEW',
        technicalTest => 'TECHNICAL_TEST',
        offer => 'OFFER',
        rejected => 'REJECTED',
        archived => 'ARCHIVED',
      };

  /// Statut a partir de la valeur API ; toute valeur inconnue retombe sur
  /// [draft] (tolerant aux ajouts backend).
  static JobApplicationStatus fromApi(String value) => switch (value) {
        'SENT' => sent,
        'INTERVIEW' => interview,
        'TECHNICAL_TEST' => technicalTest,
        'OFFER' => offer,
        'REJECTED' => rejected,
        'ARCHIVED' => archived,
        _ => draft,
      };

  /// Statuts "termines" : aucune relance n'est attendue.
  bool get isClosed =>
      this == offer || this == rejected || this == archived;
}
