import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import 'token_store.dart';

/// Coordonne le rafraichissement de la session lorsqu'une requete authentifiee
/// echoue en 401 (issue M-7).
///
/// Contrat single-flight : plusieurs requetes qui expirent simultanement
/// partagent un unique appel a `/auth/refresh` — pas de tempete de refresh.
abstract interface class SessionRefresher {
  /// Tente de rafraichir les jetons. `true` si de nouveaux jetons sont
  /// disponibles (l'appelant peut rejouer sa requete), `false` sinon
  /// (l'appelant laisse le 401 se propager -> deconnexion).
  Future<bool> refresh();
}

/// Implementation HTTP : `POST /auth/refresh {refreshToken}` via le client
/// injecte (jamais [ApiTransport], pour eviter toute recursion d'interception),
/// puis persistance des nouveaux jetons via [TokenStore].
class HttpSessionRefresher implements SessionRefresher {
  HttpSessionRefresher(
    this._client,
    this._tokens, {
    Duration timeout = const Duration(seconds: 20),
  }) : _timeout = timeout;

  final http.Client _client;
  final TokenStore _tokens;
  final Duration _timeout;

  /// Refresh en cours, partage entre appelants concurrents (single-flight).
  Future<bool>? _inFlight;

  @override
  Future<bool> refresh() =>
      _inFlight ??= _run().whenComplete(() => _inFlight = null);

  Future<bool> _run() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _client
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final access = json['accessToken'] as String?;
      final refresh = json['refreshToken'] as String?;
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        return false;
      }
      await _tokens.save(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      // Echec reseau/parse du refresh : on ne rejoue pas. Ce n'est pas un
      // fallback masque — le 401 d'origine se propage normalement en
      // AuthException cote appelant (deconnexion).
      return false;
    }
  }
}
