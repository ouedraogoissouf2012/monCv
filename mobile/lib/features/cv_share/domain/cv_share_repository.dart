import '../../../core/error/result.dart';
import '../../cv/data/cv_network_codec.dart' show Cv;

/// Port de gestion du lien de partage public d'un CV par son proprietaire
/// (issue #258, ex-#237) : activation, regeneration, desactivation et reglages.
///
/// Abstrait l'acces reseau pour que la presentation
/// (`share_portfolio_dialog.dart`) ne connaisse plus `IApiClient`.
/// L'implementation vit dans `data/`.
abstract interface class CvShareRepository {
  /// Active (ou reactive) le lien de partage public du CV [cvId].
  Future<Result<Cv>> generateLink(int cvId);

  /// Genere un nouveau token de partage, invalidant l'ancien lien.
  Future<Result<Cv>> regenerateLink(int cvId);

  /// Desactive le lien de partage public.
  Future<Result<Cv>> deactivateLink(int cvId);

  /// Met a jour les reglages du partage public (contact / telechargements).
  Future<Result<Cv>> updateSettings(
    int cvId, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  });
}
