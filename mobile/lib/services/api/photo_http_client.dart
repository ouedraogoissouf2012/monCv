import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP de l'upload de photo de profil (fichier natif ou bytes web)
/// (issue #258, ex-#237). Extrait de `ApiService`. Le chargement/telechargement
/// de photo passe par `PublicPortfolioApiClient`.
class PhotoHttpClient {
  const PhotoHttpClient({required this.accessToken});

  final AccessTokenProvider accessToken;

  /// Upload une photo de profil et retourne son URL relative.
  /// L'URL complète s'obtient avec [ApiConstants.baseUrl] + url.
  Future<String> uploadPhoto(XFile photo) async {
    final token = await accessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/uploads/photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));

    final streamed = await request.send().timeout(http.requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throwTypedError(http.Response(body, streamed.statusCode));
    }
  }

  /// Upload une photo à partir de bytes (pour le web).
  Future<String> uploadPhotoBytes(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    final token = await accessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/uploads/photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send().timeout(http.requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throwTypedError(http.Response(body, streamed.statusCode));
    }
  }
}
