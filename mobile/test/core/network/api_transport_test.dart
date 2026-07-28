import 'dart:convert';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/api_request.dart';
import 'package:cv_mobile/core/network/api_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_token_store.dart';

/// Cree un transport dont le MockClient renvoie [response] et capture la
/// derniere requete recue dans [captured].
ApiTransport _transport(
  http.Response Function(http.Request request) handler, {
  FakeTokenStore? tokens,
  Duration timeout = const Duration(seconds: 20),
}) =>
    ApiTransport(
      MockClient((request) async => handler(request)),
      tokens ?? FakeTokenStore(),
      timeout: timeout,
    );

void main() {
  group('construction de la requete', () {
    test('ajoute Content-Type, Accept et encode le corps JSON', () async {
      late http.Request captured;
      final transport = _transport((request) {
        captured = request;
        return http.Response('{"ok":true}', 200);
      });

      await transport.sendJsonObject(
        ApiRequest.post('/ai/enhance-cv', body: {'cvId': 7, 'level': 'MAX'}),
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/ai/enhance-cv'));
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      expect(captured.headers['Accept'], 'application/json');
      expect(jsonDecode(captured.body), {'cvId': 7, 'level': 'MAX'});
    });

    test('ajoute Authorization quand withAuth et jeton present', () async {
      late http.Request captured;
      final transport = _transport(
        (request) {
          captured = request;
          return http.Response('{}', 200);
        },
        tokens: FakeTokenStore(accessToken: 'jwt-123'),
      );

      await transport.sendJsonObject(ApiRequest.get('/ai/status'));

      expect(captured.headers['Authorization'], 'Bearer jwt-123');
    });

    test('omet Authorization quand withAuth est false', () async {
      late http.Request captured;
      final transport = _transport(
        (request) {
          captured = request;
          return http.Response('{}', 200);
        },
        tokens: FakeTokenStore(accessToken: 'jwt-123'),
      );

      await transport
          .sendJsonObject(ApiRequest.get('/public', withAuth: false));

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('omet Authorization quand aucun jeton n est disponible', () async {
      late http.Request captured;
      final transport = _transport((request) {
        captured = request;
        return http.Response('{}', 200);
      });

      await transport.sendJsonObject(ApiRequest.get('/ai/status'));

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('propage les query parameters', () async {
      late http.Request captured;
      final transport = _transport((request) {
        captured = request;
        return http.Response('[]', 200);
      });

      await transport.sendJsonArray(
        ApiRequest.get('/applications', query: {'status': 'SENT'}),
      );

      expect(captured.url.queryParameters['status'], 'SENT');
    });
  });

  group('dispatch par verbe', () {
    for (final entry in {
      'POST': ApiRequest.post('/x', body: const {}),
      'PUT': ApiRequest.put('/x', body: const {}),
      'DELETE': ApiRequest.delete('/x'),
    }.entries) {
      test('envoie un ${entry.key}', () async {
        late http.Request captured;
        final transport = _transport((request) {
          captured = request;
          return http.Response('{}', 200);
        });
        await transport.sendJsonObject(entry.value);
        expect(captured.method, entry.key);
      });
    }
  });

  group('mapping des status non-2xx en AppException', () {
    final cases = <int, Matcher>{
      401: isA<AuthException>(),
      403: isA<AuthException>(),
      404: isA<NotFoundException>(),
      409: isA<ConflictException>(),
      429: isA<ServerException>(),
      500: isA<ServerException>(),
      503: isA<ServerException>(),
    };
    cases.forEach((status, matcher) {
      test('status $status', () async {
        final transport = _transport(
          (_) => http.Response('{"message":"x"}', status),
        );
        await expectLater(
          transport.sendJsonObject(ApiRequest.get('/x')),
          throwsA(matcher),
        );
      });
    });

    test('400 avec details -> ValidationException', () async {
      final transport = _transport(
        (_) => http.Response(
          jsonEncode({
            'message': 'Donnees invalides',
            'details': {'email': 'requis'},
          }),
          400,
        ),
      );
      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/x')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('502 avec code AI_* -> AiException', () async {
      final transport = _transport(
        (_) => http.Response(
          jsonEncode({
            'code': 'AI_QUOTA_EXCEEDED',
            'details': {'provider': 'x', 'retryAfter': 120},
          }),
          502,
        ),
      );
      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/ai/enhance-cv')),
        throwsA(isA<AiException>()),
      );
    });

    test('corps d erreur non-JSON -> ServerException generique', () async {
      final transport = _transport((_) => http.Response('<html>500</html>', 500));
      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/x')),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('corps et statuts particuliers', () {
    test('JSON invalide sur un 200 -> ServerException', () async {
      final transport = _transport((_) => http.Response('not json', 200));
      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/x')),
        throwsA(isA<ServerException>()),
      );
    });

    test('corps binaire malforme (UTF-8 invalide) -> AppException, pas de crash',
        () async {
      // Le decodage est tolerant (allowMalformed) : aucune exception brute ne
      // doit echapper ; le corps non-JSON est rejete en erreur typee.
      final transport = ApiTransport(
        MockClient(
          (_) async => http.Response.bytes([0xFF, 0xFE, 0x00], 200),
        ),
        FakeTokenStore(),
      );
      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/x')),
        throwsA(isA<AppException>()),
      );
    });

    test('sendNoContent accepte un 204 sans corps', () async {
      final transport = _transport((_) => http.Response('', 204));
      await expectLater(
        transport.sendNoContent(ApiRequest.delete('/x')),
        completes,
      );
    });

    test('sendNoContent sur un status inattendu -> AppException', () async {
      final transport = _transport((_) => http.Response('{}', 500));
      await expectLater(
        transport.sendNoContent(ApiRequest.delete('/x')),
        throwsA(isA<ServerException>()),
      );
    });

    test('un status accepte hors 200 est honore', () async {
      final transport = _transport((_) => http.Response('{"id":1}', 201));
      final body = await transport.sendJsonObject(
        ApiRequest.post('/x', body: const {}),
        ok: const {201},
      );
      expect(body['id'], 1);
    });
  });

  group('erreurs reseau', () {
    test('un handler plus lent que le timeout -> NetworkException', () async {
      final slow = ApiTransport(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return http.Response('{}', 200);
        }),
        FakeTokenStore(),
        timeout: const Duration(milliseconds: 1),
      );
      await expectLater(
        slow.sendJsonObject(ApiRequest.get('/x')),
        throwsA(isA<NetworkException>()),
      );
    });

    test('un handler dans les temps reussit (anti faux positif)', () async {
      final fast = _transport((_) => http.Response('{"ok":true}', 200));
      final body = await fast.sendJsonObject(ApiRequest.get('/x'));
      expect(body['ok'], true);
    });
  });
}
