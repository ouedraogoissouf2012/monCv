import 'dart:convert';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/api_request.dart';
import 'package:cv_mobile/core/network/api_transport.dart';
import 'package:cv_mobile/core/network/session_refresher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_token_store.dart';

/// Refresh transparent sur 401 dans le pipeline unique (M-7).
class _SpyRefresher implements SessionRefresher {
  _SpyRefresher(this._onRefresh);

  final Future<bool> Function() _onRefresh;
  int calls = 0;

  @override
  Future<bool> refresh() {
    calls++;
    return _onRefresh();
  }
}

void main() {
  group('refresh sur 401 (M-7)', () {
    test('un 401 authentifie declenche un refresh puis rejoue avec le nouveau jeton',
        () async {
      final store = FakeTokenStore(accessToken: 'expired', refreshToken: 'r');
      final sent = <String?>[];
      var dataCalls = 0;
      final refresher = _SpyRefresher(() async {
        await store.save(accessToken: 'fresh', refreshToken: 'r2');
        return true;
      });
      final transport = ApiTransport(
        MockClient((request) async {
          sent.add(request.headers['Authorization']);
          dataCalls++;
          return http.Response('{"ok":true}', dataCalls == 1 ? 401 : 200);
        }),
        store,
        refresher: refresher,
      );

      final body = await transport.sendJsonObject(ApiRequest.get('/cvs'));

      expect(body['ok'], true);
      expect(refresher.calls, 1);
      expect(dataCalls, 2, reason: 'requete initiale + un rejeu');
      expect(sent, ['Bearer expired', 'Bearer fresh'],
          reason: 'le rejeu porte le jeton rafraichi');
    });

    test('bout-en-bout : deux 401 concurrents -> un seul /auth/refresh (single-flight)',
        () async {
      final store = FakeTokenStore(accessToken: 'expired', refreshToken: 'r');
      var refreshPosts = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshPosts++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response(
              jsonEncode({'accessToken': 'fresh', 'refreshToken': 'r2'}), 200);
        }
        final auth = request.headers['Authorization'];
        return http.Response('{}', auth == 'Bearer expired' ? 401 : 200);
      });
      final transport = ApiTransport(client, store,
          refresher: HttpSessionRefresher(client, store));

      await Future.wait([
        transport.sendJsonObject(ApiRequest.get('/cvs')),
        transport.sendJsonObject(ApiRequest.get('/applications')),
      ]);

      expect(refreshPosts, 1,
          reason: 'un seul refresh pour deux 401 simultanes');
    });

    test('refresh impossible -> 401 propage en AuthException', () async {
      final refresher = _SpyRefresher(() async => false);
      final transport = ApiTransport(
        MockClient((_) async => http.Response('{"message":"expire"}', 401)),
        FakeTokenStore(accessToken: 'expired', refreshToken: 'r'),
        refresher: refresher,
      );

      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/cvs')),
        throwsA(isA<AuthException>()),
      );
      expect(refresher.calls, 1);
    });

    test('pas de boucle : un rejeu encore 401 -> AuthException, un seul refresh',
        () async {
      final refresher = _SpyRefresher(() async => true);
      var dataCalls = 0;
      final transport = ApiTransport(
        MockClient((_) async {
          dataCalls++;
          return http.Response('{"message":"x"}', 401);
        }),
        FakeTokenStore(accessToken: 'expired', refreshToken: 'r'),
        refresher: refresher,
      );

      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/cvs')),
        throwsA(isA<AuthException>()),
      );
      expect(refresher.calls, 1, reason: 'un seul refresh');
      expect(dataCalls, 2, reason: 'requete + un seul rejeu, pas de boucle');
    });

    test('requete non authentifiee : un 401 ne declenche pas de refresh',
        () async {
      final refresher = _SpyRefresher(() async => true);
      final transport = ApiTransport(
        MockClient((_) async => http.Response('{"message":"x"}', 401)),
        FakeTokenStore(refreshToken: 'r'),
        refresher: refresher,
      );

      await expectLater(
        transport.sendJsonObject(ApiRequest.get('/public', withAuth: false)),
        throwsA(isA<AuthException>()),
      );
      expect(refresher.calls, 0, reason: 'pas de refresh sur withAuth:false');
    });
  });
}
