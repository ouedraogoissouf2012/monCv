import 'dart:convert';

import '../../core/error/error_mapper.dart';
import '../http_timeout.dart' as http;

/// Fabrique d'en-tetes HTTP (avec ou sans jeton d'authentification).
typedef HeaderFactory = Future<Map<String, String>> Function({bool withAuth});

/// Lecture du jeton d'acces courant.
typedef AccessTokenProvider = Future<String?> Function();

/// Persistance d'une paire de jetons (acces + rafraichissement).
typedef TokenStore = Future<void> Function(String accessToken, String refreshToken);

/// Purge locale des jetons (deconnexion / suppression de compte).
typedef TokenPurge = Future<void> Function();

/// Leve une [AppException] typee a partir d'une reponse HTTP en echec, via
/// [ErrorMapper]. Partage par les clients HTTP par feature (issue #258, ex-#237).
Never throwTypedError(http.Response response) {
  Map<String, dynamic>? body;
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    // Body non-JSON : on passe null au mapper.
  }
  throw ErrorMapper.fromHttpResponse(response.statusCode, body);
}

/// Leve une [Exception] encapsulant le corps d'erreur JSON (complete par le
/// statut et [fallbackMessage] s'ils manquent), ou un simple message si le corps
/// n'est pas du JSON exploitable.
Never throwApiError(http.Response response, String fallbackMessage) {
  Map<String, dynamic>? body;
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      body = Map<String, dynamic>.from(decoded);
      body['status'] ??= response.statusCode;
      body['message'] ??= fallbackMessage;
    }
  } catch (_) {
    // Retombe sur un message simple si le corps n'est pas du JSON valide.
  }

  if (body != null) throw Exception(jsonEncode(body));
  throw Exception(fallbackMessage);
}
