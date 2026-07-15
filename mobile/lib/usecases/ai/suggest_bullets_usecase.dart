import '../../core/error/result.dart';
import '../../core/error/safe_call.dart';
import '../../core/usecase/usecase.dart';
import '../../services/i_api_client.dart';

class SuggestBulletsParams {
  final String poste;
  final String? entreprise;
  const SuggestBulletsParams({required this.poste, this.entreprise});
}

class SuggestBulletsUseCase
    implements UseCase<List<String>, SuggestBulletsParams> {
  final IApiClient _api;
  const SuggestBulletsUseCase(this._api);

  @override
  Future<Result<List<String>>> call(SuggestBulletsParams params) =>
      safeCall(() => _api.getAiSuggestions(
          poste: params.poste, entreprise: params.entreprise));
}
