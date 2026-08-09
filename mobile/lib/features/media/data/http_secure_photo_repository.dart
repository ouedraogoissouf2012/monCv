import 'dart:typed_data';

import '../../../services/i_api_client.dart';
import '../domain/secure_photo_repository.dart';

/// Implementation HTTP de [SecurePhotoRepository] (issue #258).
///
/// Delegue a [IApiClient.loadPhoto] (qui joint le jeton et valide la reponse via
/// le client de portfolio public). Seule cette couche `data` connait le
/// transport ; le widget [SecurePhoto] ne le voit jamais.
class HttpSecurePhotoRepository implements SecurePhotoRepository {
  const HttpSecurePhotoRepository(this._api);

  final IApiClient _api;

  @override
  Future<Uint8List?> load(String url) => _api.loadPhoto(url);
}
