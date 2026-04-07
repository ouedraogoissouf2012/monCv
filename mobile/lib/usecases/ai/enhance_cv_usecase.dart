import '../../core/error/result.dart';
import '../../core/error/safe_call.dart';
import '../../core/usecase/usecase.dart';
import '../../services/api_service.dart';

class EnhanceCvParams {
  final int cvId;
  final String level;
  const EnhanceCvParams({required this.cvId, required this.level});
}

class EnhanceCvUseCase implements UseCase<Map<String, dynamic>, EnhanceCvParams> {
  final ApiService _api;
  const EnhanceCvUseCase(this._api);

  @override
  Future<Result<Map<String, dynamic>>> call(EnhanceCvParams params) =>
      safeCall(() => _api.enhanceCv(params.cvId, params.level));
}
