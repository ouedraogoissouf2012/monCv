import '../../../core/network/api_request.dart';
import '../../../core/network/api_transport.dart';
import '../../../models/ai_status.dart';
import '../domain/entities/application_messages.dart';
import '../domain/entities/enhanced_cv.dart';
import '../domain/entities/job_match.dart';
import 'dto/application_messages_dto.dart';
import 'dto/enhanced_cv_dto.dart';
import 'dto/job_match_dto.dart';
import 'mapper/application_messages_mapper.dart';
import 'mapper/enhanced_cv_mapper.dart';
import 'mapper/job_match_mapper.dart';

/// Port etroit du sous-systeme IA cote data. Retourne des entités de domaine :
/// aucun `Map<String, dynamic>` ne franchit cette frontiere. Peut lever une
/// [AppException] (traduite par le transport) ; le repository la convertit en
/// [Result].
abstract interface class AiRemoteDataSource {
  Future<EnhancedCv> enhanceCv(int cvId, String level);
  Future<JobMatch> matchJob(int cvId, String jobDescription);
  Future<ApplicationMessages> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  );
  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  );
  Future<List<String>> getSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  });
  Future<AiStatus> getStatus();
}

/// Implementation HTTP sur [ApiTransport]. Les corps de requete sont identiques
/// a ceux de l'ancien `ApiService` (verrouilles par les tests de contrat).
class HttpAiRemoteDataSource implements AiRemoteDataSource {
  HttpAiRemoteDataSource(this._transport);

  final ApiTransport _transport;

  @override
  Future<EnhancedCv> enhanceCv(int cvId, String level) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/ai/enhance-cv', body: {
        'cvId': cvId,
        'level': level,
        'aiConsentAccepted': true,
      }),
    );
    return EnhancedCvMapper.fromDto(EnhancedCvDto.fromJson(json));
  }

  @override
  Future<JobMatch> matchJob(int cvId, String jobDescription) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/ai/match-job', body: {
        'cvId': cvId,
        'jobDescription': jobDescription,
        'aiConsentAccepted': true,
      }),
    );
    return JobMatchMapper.fromDto(JobMatchDto.fromJson(json));
  }

  @override
  Future<ApplicationMessages> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  ) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/ai/application-messages', body: {
        'cvId': cvId,
        'jobDescription': jobDescription,
        'tone': tone,
        'aiConsentAccepted': true,
      }),
    );
    return ApplicationMessagesMapper.fromDto(
      ApplicationMessagesDto.fromJson(json),
    );
  }

  @override
  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  ) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/ai/generate-resume', body: {
        'titrePoste': titrePoste ?? '',
        'competences': competences ?? '',
        'experience': experience ?? '',
        'aiConsentAccepted': true,
      }),
    );
    return json['resume'] as String? ?? '';
  }

  @override
  Future<List<String>> getSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  }) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/ai/suggest', body: {
        'poste': poste,
        if (entreprise != null && entreprise.isNotEmpty) 'entreprise': entreprise,
        if (description != null && description.isNotEmpty)
          'description': description,
      }),
    );
    final raw = json['suggestions'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  @override
  Future<AiStatus> getStatus() async {
    final json = await _transport.sendJsonObject(ApiRequest.get('/ai/status'));
    return AiStatus.fromJson(json);
  }
}
