import 'dart:convert';

import 'package:cv_mobile/core/network/session_refresher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_token_store.dart';

/// Rafraichissement de session single-flight (M-7).
void main() {
  http.Response tokens(String access, String refresh) => http.Response(
        jsonEncode({'accessToken': access, 'refreshToken': refresh}),
        200,
      );

  group('HttpSessionRefresher (M-7)', () {
    test('POST /auth/refresh avec le refresh token, sauve les nouveaux jetons',
        () async {
      late http.Request captured;
      final store = FakeTokenStore(accessToken: 'old', refreshToken: 'refresh-abc');
      final refresher = HttpSessionRefresher(
        MockClient((request) async {
          captured = request;
          return tokens('new-access', 'new-refresh');
        }),
        store,
      );

      final ok = await refresher.refresh();

      expect(ok, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/auth/refresh'));
      expect(jsonDecode(captured.body), {'refreshToken': 'refresh-abc'});
      expect(await store.readAccessToken(), 'new-access');
      expect(await store.readRefreshToken(), 'new-refresh');
    });

    test('sans refresh token -> false, aucun appel reseau', () async {
      var called = false;
      final refresher = HttpSessionRefresher(
        MockClient((_) async {
          called = true;
          return tokens('a', 'b');
        }),
        FakeTokenStore(),
      );

      expect(await refresher.refresh(), isFalse);
      expect(called, isFalse, reason: 'aucun appel /auth/refresh sans refresh token');
    });

    test('reponse non-200 -> false, jetons inchanges', () async {
      final store = FakeTokenStore(accessToken: 'old', refreshToken: 'r');
      final refresher = HttpSessionRefresher(
        MockClient((_) async => http.Response('{"message":"expire"}', 401)),
        store,
      );

      expect(await refresher.refresh(), isFalse);
      expect(await store.readAccessToken(), 'old');
      expect(await store.readRefreshToken(), 'r');
    });

    test('single-flight : deux refresh concurrents -> un seul POST', () async {
      var posts = 0;
      final refresher = HttpSessionRefresher(
        MockClient((_) async {
          posts++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return tokens('a', 'b');
        }),
        FakeTokenStore(refreshToken: 'r'),
      );

      final results =
          await Future.wait([refresher.refresh(), refresher.refresh()]);

      expect(results, [true, true]);
      expect(posts, 1, reason: 'un seul /auth/refresh pour deux demandes simultanees');
    });

    test('un refresh ulterieur redéclenche un POST (pas de cache indefini)',
        () async {
      var posts = 0;
      final refresher = HttpSessionRefresher(
        MockClient((_) async {
          posts++;
          return tokens('a', 'b');
        }),
        FakeTokenStore(refreshToken: 'r'),
      );

      await refresher.refresh();
      await refresher.refresh();

      expect(posts, 2);
    });
  });
}
