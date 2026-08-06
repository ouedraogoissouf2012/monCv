import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Support de test partage par les suites de clients HTTP par feature
/// (issue #258). Ce fichier n'est pas une suite (`*_test.dart`) : il n'est
/// jamais execute directement, seulement importe.

/// Entetes de test : evitent toute dependance a TokenStorage (plateforme).
/// Les clients HTTP sont decouples du stockage par injection de callbacks,
/// c'est ce qui les rend testables en isolation. Reference de fonction
/// top-level => constante, donc utilisable avec les constructeurs `const`.
Future<Map<String, String>> fakeHeaders({bool withAuth = true}) async => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (withAuth) 'Authorization': 'Bearer test-token',
    };

/// Corps d'une reponse d'authentification valide (login / register).
String authResponseBody() => jsonEncode({
      'accessToken': 'acc',
      'refreshToken': 'ref',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'user': {'id': 1, 'email': 'a@b.c', 'role': 'USER'},
    });

/// Execute [body] avec un [MockClient] ambiant qui capte la requete sortante
/// (via `runWithClient`, intercepte aussi les envois multipart/streames).
Future<T> withMockClient<T>(
  Future<T> Function() body,
  http.Response Function(http.Request request) respond, {
  void Function(http.Request request)? onRequest,
}) {
  return http.runWithClient(
    body,
    () => MockClient((request) async {
      onRequest?.call(request);
      return respond(request);
    }),
  );
}
