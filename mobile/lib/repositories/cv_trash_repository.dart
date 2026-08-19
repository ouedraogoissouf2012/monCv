import '../core/error/result.dart';
import '../core/error/safe_call.dart';
import '../features/cv/presentation/cv_presentation_model.dart';
import '../services/i_api_client.dart';

class CvTrashRepository {
  CvTrashRepository({required IApiClient api}) : _api = api;

  final IApiClient _api;

  Future<Result<List<Cv>>> list() => safeCall(_api.getTrashedCvs);

  Future<Result<Cv>> restore(int id) => safeCall(() => _api.restoreCv(id));

  Future<Result<void>> purge(int id) => safeCall(() => _api.purgeCv(id));
}
