import '../../../core/error/error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../services/i_api_client.dart';
import '../../cv/data/cv_network_codec.dart' show Cv;
import '../domain/cv_share_repository.dart';

/// Implementation HTTP de [CvShareRepository] (issue #258).
///
/// Enveloppe [IApiClient] et convertit ses exceptions typees en [Result] via
/// [FutureResultExtension.toResult]. Seule cette couche `data` connait le
/// transport ; le dialogue de partage ne le voit jamais.
class HttpCvShareRepository implements CvShareRepository {
  const HttpCvShareRepository(this._api);

  final IApiClient _api;

  @override
  Future<Result<Cv>> generateLink(int cvId) =>
      _api.generateShareLink(cvId).toResult();

  @override
  Future<Result<Cv>> regenerateLink(int cvId) =>
      _api.regenerateShareLink(cvId).toResult();

  @override
  Future<Result<Cv>> deactivateLink(int cvId) =>
      _api.deactivateShareLink(cvId).toResult();

  @override
  Future<Result<Cv>> updateSettings(
    int cvId, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  }) =>
      _api
          .updateShareSettings(
            cvId,
            contactEnabled: contactEnabled,
            downloadsEnabled: downloadsEnabled,
          )
          .toResult();
}
