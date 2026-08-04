import '../../../core/network/api_request.dart';
import '../../../core/network/api_transport.dart';
import '../domain/job_application.dart';
import '../domain/job_application_status.dart';
import 'job_application_dto.dart';

/// Port etroit du sous-systeme candidatures cote data (issue #246, A2).
///
/// Retourne des entités de domaine : aucun `Map<String, dynamic>` ne franchit
/// cette frontiere. Peut lever une [AppException] (traduite par le transport) ;
/// le repository la convertit en [Result].
abstract interface class ApplicationRemoteDataSource {
  Future<List<JobApplication>> list({JobApplicationStatus? status});
  Future<JobApplication> create(JobApplication application);
  Future<JobApplication> update(JobApplication application);
  Future<void> delete(int id);
}

/// Implementation HTTP sur [ApiTransport]. Chemins et corps identiques a
/// l'ancien `ApiService` (contrat verrouille par #237).
class HttpApplicationRemoteDataSource implements ApplicationRemoteDataSource {
  HttpApplicationRemoteDataSource(this._transport);

  final ApiTransport _transport;

  @override
  Future<List<JobApplication>> list({JobApplicationStatus? status}) async {
    final json = await _transport.sendJsonArray(
      ApiRequest.get(
        '/applications',
        query: {if (status != null) 'status': status.apiValue},
      ),
    );
    return json
        .map((item) =>
            JobApplicationDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<JobApplication> create(JobApplication application) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.post('/applications',
          body: JobApplicationDto.toJson(application)),
      ok: const {200, 201},
    );
    return JobApplicationDto.fromJson(json);
  }

  @override
  Future<JobApplication> update(JobApplication application) async {
    final json = await _transport.sendJsonObject(
      ApiRequest.put('/applications/${application.id}',
          body: JobApplicationDto.toJson(application)),
      ok: const {200},
    );
    return JobApplicationDto.fromJson(json);
  }

  @override
  Future<void> delete(int id) => _transport.sendNoContent(
        ApiRequest.delete('/applications/$id'),
        ok: const {200, 204},
      );
}
