import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/repositories/ai_repository.dart';

class SuggestBulletsParams {
  final String poste;
  final String? entreprise;
  final String? description;
  final bool consentAccepted;
  const SuggestBulletsParams({
    required this.poste,
    this.entreprise,
    this.description,
    required this.consentAccepted,
  });
}

/// Genere des suggestions de bullet points via le port [AiRepository].
class SuggestBulletsUseCase
    implements UseCase<List<String>, SuggestBulletsParams> {
  final AiRepository _repository;
  const SuggestBulletsUseCase(this._repository);

  @override
  Future<Result<List<String>>> call(SuggestBulletsParams params) =>
      _repository.getSuggestions(
        poste: params.poste,
        entreprise: params.entreprise,
        description: params.description,
        consentAccepted: params.consentAccepted,
      );
}
