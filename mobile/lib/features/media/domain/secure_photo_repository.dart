import 'dart:typed_data';

/// Port de chargement d'une image securisee par URL (issue #258, ex-#237).
///
/// Abstrait l'acces reseau pour que la presentation ([SecurePhoto]) ne
/// connaisse plus `IApiClient`. **Best-effort** : retourne `null` quand l'image
/// est indisponible (l'appelant affiche un fallback) — aucune exception a gerer.
abstract interface class SecurePhotoRepository {
  /// Charge les octets de l'image protegee referencee par [url], ou `null`.
  Future<Uint8List?> load(String url);
}
