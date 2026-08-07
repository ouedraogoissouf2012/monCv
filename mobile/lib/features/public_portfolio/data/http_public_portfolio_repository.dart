import '../../../core/error/error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../services/i_api_client.dart';
import '../../cv/data/cv_network_codec.dart' show Cv;
import '../domain/public_portfolio_repository.dart';

/// Implementation HTTP de [PublicPortfolioRepository] (issue #258).
///
/// Enveloppe [IApiClient] et convertit ses exceptions typees en [Result] via
/// [FutureResultExtension.toResult]. Seule cette couche `data` connait le
/// transport ; l'ecran public ne le voit jamais.
class HttpPublicPortfolioRepository implements PublicPortfolioRepository {
  const HttpPublicPortfolioRepository(this._api);

  final IApiClient _api;

  @override
  Future<Result<Cv>> getPortfolio(String token) =>
      _api.getPublicCv(token).toResult();

  @override
  Future<Result<List<int>>> download(String token, String format) =>
      _api.downloadPublicCv(token, format).toResult();

  @override
  Future<void> trackShare(String token) async {
    // Best-effort : une erreur de metrique est absorbee ici, jamais propagee.
    try {
      await _api.trackPublicShare(token);
    } catch (_) {
      // Metrique non critique : ignoree volontairement.
    }
  }
}
