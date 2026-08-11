import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../utils/constants.dart';
import '../error/error_mapper.dart';
import '../error/result.dart';
import 'api_request.dart';
import 'api_response.dart';
import 'session_refresher.dart';
import 'token_store.dart';

/// Contenu d'un upload multipart : soit un fichier sur disque, soit des octets
/// en memoire (web / import). Scelle pour un traitement exhaustif.
sealed class MultipartPayload {
  const MultipartPayload();
}

/// Fichier reference par son chemin sur disque (mobile/desktop).
final class FilePathPayload extends MultipartPayload {
  const FilePathPayload(this.path);
  final String path;
}

/// Octets en memoire, avec nom de fichier et type MIME explicites.
final class BytesPayload extends MultipartPayload {
  const BytesPayload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final MediaType contentType;
}

/// Primitive multipart partagee par tous les uploads (photo fichier, photo
/// bytes, import CV). Meme construction de l'entete d'authentification et meme
/// mapping d'erreurs que [ApiTransport] : c'est la seule voie multipart de
/// l'application.
class MultipartTransport {
  MultipartTransport(
    this._client,
    this._tokens, {
    SessionRefresher? refresher,
    Duration timeout = const Duration(seconds: 20),
  })  : _refresher = refresher,
        _timeout = timeout;

  final http.Client _client;
  final TokenStore _tokens;

  /// Rafraichisseur de session, invoque sur un 401 authentifie (M-7). `null`
  /// desactive l'interception (comportement historique preserve).
  final SessionRefresher? _refresher;

  final Duration _timeout;

  /// Envoie [payload] en multipart/form-data sous le champ [field] et retourne
  /// la reponse normalisee, sans juger du status (l'appelant decide). Les
  /// erreurs reseau/systeme sont deja traduites en [AppException].
  Future<ApiResponse> upload({
    required String path,
    required MultipartPayload payload,
    HttpMethod method = HttpMethod.post,
    String field = 'file',
    bool withAuth = true,
  }) async {
    var response = await _sendOnce(
        path: path,
        payload: payload,
        method: method,
        field: field,
        withAuth: withAuth);

    // 401 sur un upload authentifie : refresh (single-flight cote
    // [SessionRefresher]) puis rejeu UNE fois avec le nouveau jeton (M-7).
    // Memes garde-fous que ApiTransport ; la requete multipart est reconstruite
    // (un MultipartRequest n'est pas rejouable).
    if (response.statusCode == 401 && withAuth && _refresher != null) {
      final refreshed = await _refresher!.refresh();
      if (refreshed) {
        response = await _sendOnce(
            path: path,
            payload: payload,
            method: method,
            field: field,
            withAuth: withAuth);
      }
    }
    return response;
  }

  Future<ApiResponse> _sendOnce({
    required String path,
    required MultipartPayload payload,
    required HttpMethod method,
    required String field,
    required bool withAuth,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final request = http.MultipartRequest(_methodName(method), uri);

    if (withAuth) {
      final token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.files.add(await _buildFile(field, payload));

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        bodyBytes: Uint8List.fromList(response.bodyBytes),
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw ErrorMapper.fromException(error);
    }
  }

  /// Envoie [payload] et exige un status dans [ok], puis retourne le corps
  /// decode en objet JSON. Tout autre status est traduit via [ErrorMapper].
  Future<Map<String, dynamic>> uploadJsonObject({
    required String path,
    required MultipartPayload payload,
    Set<int> ok = const {200},
    String field = 'file',
    bool withAuth = true,
  }) async {
    final response = await upload(
      path: path,
      payload: payload,
      field: field,
      withAuth: withAuth,
    );
    if (!ok.contains(response.statusCode)) {
      throw ErrorMapper.fromHttpResponse(
        response.statusCode,
        response.jsonOrNull,
      );
    }
    try {
      return response.jsonObject;
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    }
  }

  Future<http.MultipartFile> _buildFile(
    String field,
    MultipartPayload payload,
  ) async {
    return switch (payload) {
      FilePathPayload(:final path) =>
        await http.MultipartFile.fromPath(field, path),
      BytesPayload(:final bytes, :final filename, :final contentType) =>
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: contentType,
        ),
    };
  }

  String _methodName(HttpMethod method) => switch (method) {
        HttpMethod.get => 'GET',
        HttpMethod.post => 'POST',
        HttpMethod.put => 'PUT',
        HttpMethod.delete => 'DELETE',
      };
}
