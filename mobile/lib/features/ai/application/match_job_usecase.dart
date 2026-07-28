import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/job_match.dart';
import '../domain/repositories/ai_repository.dart';

class MatchJobParams {
  final int cvId;
  final String jobDescription;
  const MatchJobParams({required this.cvId, required this.jobDescription});
}

/// Analyse la correspondance CV / offre via le port [AiRepository].
/// Retourne une entité typee [JobMatch].
class MatchJobUseCase implements UseCase<JobMatch, MatchJobParams> {
  final AiRepository _repository;
  const MatchJobUseCase(this._repository);

  @override
  Future<Result<JobMatch>> call(MatchJobParams params) =>
      _repository.matchJob(params.cvId, params.jobDescription);
}
