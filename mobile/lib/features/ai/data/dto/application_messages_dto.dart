/// DTO du payload backend `ApplicationMessagesResponse`
/// (endpoint `/ai/application-messages`).
class ApplicationMessagesDto {
  final String? coverLetter;
  final String? email;
  final String? linkedIn;
  final String? whatsApp;
  final String? tone;
  final bool aiGenerated;
  final bool fallback;

  const ApplicationMessagesDto({
    this.coverLetter,
    this.email,
    this.linkedIn,
    this.whatsApp,
    this.tone,
    this.aiGenerated = false,
    this.fallback = false,
  });

  factory ApplicationMessagesDto.fromJson(Map<String, dynamic> json) =>
      ApplicationMessagesDto(
        coverLetter: json['coverLetter'] as String?,
        email: json['email'] as String?,
        linkedIn: json['linkedIn'] as String?,
        whatsApp: json['whatsApp'] as String?,
        tone: json['tone'] as String?,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
        fallback: json['fallback'] as bool? ?? false,
      );
}
