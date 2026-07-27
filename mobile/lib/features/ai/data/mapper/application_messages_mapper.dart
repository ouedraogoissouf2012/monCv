import '../../domain/entities/application_messages.dart';
import '../dto/application_messages_dto.dart';

/// Convertit le DTO `ApplicationMessagesResponse` en entité de domaine.
abstract final class ApplicationMessagesMapper {
  static ApplicationMessages fromDto(ApplicationMessagesDto dto) =>
      ApplicationMessages(
        coverLetter: dto.coverLetter,
        email: dto.email,
        linkedIn: dto.linkedIn,
        whatsApp: dto.whatsApp,
        tone: dto.tone,
        aiGenerated: dto.aiGenerated,
        fallback: dto.fallback,
      );
}
