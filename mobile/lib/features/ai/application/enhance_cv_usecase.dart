import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/enhanced_cv.dart';
import '../domain/repositories/ai_repository.dart';

class EnhanceCvParams {
  final int cvId;
  final String level;
  const EnhanceCvParams({required this.cvId, required this.level});
}

/// Ameliore un CV via le port [AiRepository]. Retourne une entité typee
/// [EnhancedCv] — plus aucun `Map` ne remonte vers la presentation.
class EnhanceCvUseCase implements UseCase<EnhancedCv, EnhanceCvParams> {
  final AiRepository _repository;
  const EnhanceCvUseCase(this._repository);

  @override
  Future<Result<EnhancedCv>> call(EnhanceCvParams params) =>
      _repository.enhanceCv(params.cvId, params.level);
}
