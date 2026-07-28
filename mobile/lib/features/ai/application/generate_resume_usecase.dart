import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/repositories/ai_repository.dart';

class GenerateResumeParams {
  final String? titrePoste;
  final String? competences;
  final String? experience;
  const GenerateResumeParams({
    this.titrePoste,
    this.competences,
    this.experience,
  });
}

/// Genere un resume professionnel via le port [AiRepository].
class GenerateResumeUseCase implements UseCase<String, GenerateResumeParams> {
  final AiRepository _repository;
  const GenerateResumeUseCase(this._repository);

  @override
  Future<Result<String>> call(GenerateResumeParams params) =>
      _repository.generateResume(
        params.titrePoste,
        params.competences,
        params.experience,
      );
}
