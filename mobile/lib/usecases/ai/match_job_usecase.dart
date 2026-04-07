import '../../core/error/result.dart';
import '../../core/error/safe_call.dart';
import '../../core/usecase/usecase.dart';
import '../../services/api_service.dart';

class MatchJobParams {
  final int cvId;
  final String jobDescription;
  const MatchJobParams({required this.cvId, required this.jobDescription});
}

class MatchJobUseCase implements UseCase<Map<String, dynamic>, MatchJobParams> {
  final ApiService _api;
  const MatchJobUseCase(this._api);

  @override
  Future<Result<Map<String, dynamic>>> call(MatchJobParams params) =>
      safeCall(() => _api.matchJob(params.cvId, params.jobDescription));
}
