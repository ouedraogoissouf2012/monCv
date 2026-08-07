import '../../../core/error/result.dart';
import '../../cv/data/cv_network_codec.dart' show Cv;

/// Port du portfolio public consulte par un visiteur non authentifie
/// (issue #258, ex-#237).
///
/// Abstrait l'acces reseau pour que l'ecran public
/// (`public_portfolio_screen.dart`) ne connaisse plus `IApiClient`.
/// L'implementation vit dans `data/`.
abstract interface class PublicPortfolioRepository {
  /// Charge le CV public identifie par [token].
  Future<Result<Cv>> getPortfolio(String token);

  /// Telecharge le CV public au format demande (`pdf` ou `docx`).
  Future<Result<List<int>>> download(String token, String format);

  /// Enregistre un partage (metrique). **Best-effort** : n'echoue jamais
  /// vis-a-vis de l'appelant — une metrique indisponible ne doit pas bloquer
  /// le partage.
  Future<void> trackShare(String token);
}
