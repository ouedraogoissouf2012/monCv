import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import '../error/error_mapper.dart';
import '../error/result.dart';
import 'api_request.dart';
import 'api_response.dart';
import 'session_refresher.dart';
import 'token_store.dart';

/// Pipeline HTTP unique de l'application.
///
/// Responsabilites : construction de l'URI et des entetes (dont l'entete
/// d'authentification), encodage JSON, application du timeout, conversion des
/// exceptions systeme et des status non-2xx en [AppException] typees via
/// [ErrorMapper]. Il ne construit **aucun** message destine a l'utilisateur.
///
/// Le client HTTP et le [TokenStore] sont injectes : les tests fournissent un
/// `MockClient` et un store en memoire.
class ApiTransport {
  ApiTransport(
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

  /// Execute [request] et retourne la reponse brute normalisee, sans juger du
  /// status : c'est a l'appelant (data source) de decider quels status sont
  /// acceptables. Toute erreur reseau/systeme est deja traduite en
  /// [AppException].
  Future<ApiResponse> send(ApiRequest request) => refreshAndRetryOn401(
        refresher: _refresher,
        withAuth: request.withAuth,
        attempt: () => _dispatchOnce(request),
      );

  Future<ApiResponse> _dispatchOnce(ApiRequest request) async {
    final uri = _buildUri(request);
    final headers = await _buildHeaders(request);
    final encodedBody = request.body == null ? null : jsonEncode(request.body);
    final timeout = request.timeout ?? _timeout;

    try {
      final response = await _dispatch(request.method, uri, headers, encodedBody)
          .timeout(timeout);
      return _toApiResponse(response);
    } on AppException {
      rethrow;
    } catch (error) {
      // SocketException -> NetworkException, TimeoutException -> TIMEOUT,
      // FormatException -> ServerException, etc. (voir ErrorMapper).
      throw ErrorMapper.fromException(error);
    }
  }

  /// Envoie [request], exige un status dans [ok] (200 par defaut) et retourne le
  /// corps decode en objet JSON. Tout autre status est traduit via
  /// [ErrorMapper.fromHttpResponse]; un corps JSON invalide sur un status
  /// accepte devient une [ServerException].
  Future<Map<String, dynamic>> sendJsonObject(
    ApiRequest request, {
    Set<int> ok = const {200},
  }) async {
    final response = await send(request);
    if (!ok.contains(response.statusCode)) _fail(response);
    try {
      return response.jsonObject;
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    }
  }

  /// Variante de [sendJsonObject] pour un corps tableau JSON.
  Future<List<dynamic>> sendJsonArray(
    ApiRequest request, {
    Set<int> ok = const {200},
  }) async {
    final response = await send(request);
    if (!ok.contains(response.statusCode)) _fail(response);
    try {
      return response.jsonArray;
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    }
  }

  /// Envoie [request] et exige un status dans [ok] sans corps attendu (ex. 204).
  Future<void> sendNoContent(
    ApiRequest request, {
    Set<int> ok = const {204},
  }) async {
    final response = await send(request);
    if (!ok.contains(response.statusCode)) _fail(response);
  }

  Uri _buildUri(ApiRequest request) {
    final uri = Uri.parse('${ApiConstants.baseUrl}${request.path}');
    if (request.query.isEmpty) return uri;
    return uri.replace(queryParameters: request.query);
  }

  Future<Map<String, String>> _buildHeaders(ApiRequest request) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (request.withAuth) {
      final token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _dispatch(
    HttpMethod method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case HttpMethod.get:
        return _client.get(uri, headers: headers);
      case HttpMethod.post:
        return _client.post(uri, headers: headers, body: body);
      case HttpMethod.put:
        return _client.put(uri, headers: headers, body: body);
      case HttpMethod.delete:
        return _client.delete(uri, headers: headers, body: body);
    }
  }

  ApiResponse _toApiResponse(http.Response response) => ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        bodyBytes: Uint8List.fromList(response.bodyBytes),
      );

  Never _fail(ApiResponse response) =>
      throw ErrorMapper.fromHttpResponse(response.statusCode, response.jsonOrNull);
}
