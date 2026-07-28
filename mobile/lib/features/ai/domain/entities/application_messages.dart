/// Textes de candidature générés par l'IA (endpoint `/ai/application-messages`).
///
/// Entité de domaine : Dart pur, sans Flutter, HTTP ni JSON.
class ApplicationMessages {
  final String? coverLetter;
  final String? email;
  final String? linkedIn;
  final String? whatsApp;
  final String? tone;
  final bool aiGenerated;
  final bool fallback;

  const ApplicationMessages({
    this.coverLetter,
    this.email,
    this.linkedIn,
    this.whatsApp,
    this.tone,
    this.aiGenerated = false,
    this.fallback = false,
  });
}
