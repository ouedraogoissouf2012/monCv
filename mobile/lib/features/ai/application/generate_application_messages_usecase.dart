import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/application_messages.dart';
import '../domain/repositories/ai_repository.dart';

class GenerateApplicationMessagesParams {
  final int cvId;
  final String jobDescription;
  final String tone;
  const GenerateApplicationMessagesParams({
    required this.cvId,
    required this.jobDescription,
    required this.tone,
  });
}

/// Genere les textes de candidature via le port [AiRepository].
/// Retourne une entité typee [ApplicationMessages].
class GenerateApplicationMessagesUseCase
    implements
        UseCase<ApplicationMessages, GenerateApplicationMessagesParams> {
  final AiRepository _repository;
  const GenerateApplicationMessagesUseCase(this._repository);

  @override
  Future<Result<ApplicationMessages>> call(
    GenerateApplicationMessagesParams params,
  ) =>
      _repository.generateApplicationMessages(
        params.cvId,
        params.jobDescription,
        params.tone,
      );
}
