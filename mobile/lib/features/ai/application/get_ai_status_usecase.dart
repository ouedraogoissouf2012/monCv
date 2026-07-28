import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../../../models/ai_status.dart';
import '../domain/repositories/ai_repository.dart';

/// Recupere l'etat du sous-systeme IA via le port [AiRepository].
/// Alimente `AiStatusProvider` (au demarrage et apres chaque echec IA).
class GetAiStatusUseCase implements UseCase<AiStatus, NoParams> {
  final AiRepository _repository;
  const GetAiStatusUseCase(this._repository);

  @override
  Future<Result<AiStatus>> call(NoParams params) => _repository.getStatus();
}
