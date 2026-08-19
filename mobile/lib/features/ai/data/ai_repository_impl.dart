import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../../../models/ai_status.dart';
import '../domain/entities/application_messages.dart';
import '../domain/entities/enhanced_cv.dart';
import '../domain/entities/job_match.dart';
import '../domain/repositories/ai_repository.dart';
import 'ai_remote_data_source.dart';

/// Implementation de [AiRepository] : chaque appel au data source est enveloppe
/// dans [safeCall], qui convertit toute [AppException] en [Result.failure] et
/// tout succes en [Result.success]. C'est l'unique frontiere entre exceptions
/// et `Result` pour le sous-systeme IA.
class HttpAiRepository implements AiRepository {
  HttpAiRepository(this._dataSource);

  final AiRemoteDataSource _dataSource;

  @override
  Future<Result<EnhancedCv>> enhanceCv(int cvId, String level,
          {required bool consentAccepted}) =>
      safeCall(() => _dataSource.enhanceCv(cvId, level,
          consentAccepted: consentAccepted));

  @override
  Future<Result<JobMatch>> matchJob(int cvId, String jobDescription,
          {required bool consentAccepted}) =>
      safeCall(() => _dataSource.matchJob(cvId, jobDescription,
          consentAccepted: consentAccepted));

  @override
  Future<Result<ApplicationMessages>> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  ) =>
      safeCall(() => _dataSource.generateApplicationMessages(
            cvId,
            jobDescription,
            tone,
          ));

  @override
  Future<Result<String>> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  ) =>
      safeCall(() => _dataSource.generateResume(
            titrePoste,
            competences,
            experience,
          ));

  @override
  Future<Result<List<String>>> getSuggestions({
    required String poste,
    String? entreprise,
    String? description,
    required bool consentAccepted,
  }) =>
      safeCall(() => _dataSource.getSuggestions(
            poste: poste,
            entreprise: entreprise,
            description: description,
            consentAccepted: consentAccepted,
          ));

  @override
  Future<Result<AiStatus>> getStatus() =>
      safeCall(() => _dataSource.getStatus());
}
