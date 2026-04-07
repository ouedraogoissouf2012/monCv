import '../../core/error/result.dart';
import '../../core/error/safe_call.dart';
import '../../core/usecase/usecase.dart';
import '../../services/api_service.dart';

class GenerateResumeParams {
  final String? titrePoste;
  final String? competences;
  final String? experience;
  const GenerateResumeParams({this.titrePoste, this.competences, this.experience});
}

class GenerateResumeUseCase implements UseCase<String, GenerateResumeParams> {
  final ApiService _api;
  const GenerateResumeUseCase(this._api);

  @override
  Future<Result<String>> call(GenerateResumeParams params) =>
      safeCall(() => _api.generateResume(params.titrePoste, params.competences, params.experience));
}
