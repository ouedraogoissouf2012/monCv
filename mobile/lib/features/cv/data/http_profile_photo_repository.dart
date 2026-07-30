import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../../../services/i_api_client.dart';
import '../domain/repositories/profile_photo_repository.dart';

/// Implementation transport de [ProfilePhotoRepository] (issue #242).
///
/// Unique frontiere autorisee a appeler le transport ([IApiClient]) : chaque
/// appel est enveloppe dans [safeCall] (exception -> [Result.failure]). C'est
/// aussi ici — et non dans la presentation — qu'est construite l'URL ABSOLUE a
/// partir de l'URL relative renvoyee par le backend.
class HttpProfilePhotoRepository implements ProfilePhotoRepository {
  HttpProfilePhotoRepository(this._api, {required this.mediaBaseUrl});

  final IApiClient _api;

  /// Base des medias (URL de l'API sans le suffixe `/api`). Injectee pour que
  /// la couche data ne depende pas d'un singleton de configuration.
  final String mediaBaseUrl;

  @override
  Future<Result<String>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) =>
      safeCall(() async {
        final relative = await _api.uploadPhotoBytes(bytes, filename, mimeType);
        return _toAbsolute(relative);
      });

  @override
  Future<Result<String>> uploadFile(String path) => safeCall(() async {
        final relative = await _api.uploadPhoto(XFile(path));
        return _toAbsolute(relative);
      });

  /// Concatene l'URL relative du backend a la base des medias. Si le backend
  /// renvoie deja une URL absolue, la retourne telle quelle.
  String _toAbsolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$mediaBaseUrl$url';
  }
}
