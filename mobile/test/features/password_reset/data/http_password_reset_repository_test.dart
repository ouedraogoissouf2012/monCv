import 'dart:convert';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/api_transport.dart';
import 'package:cv_mobile/features/password_reset/data/http_password_reset_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../core/network/fake_token_store.dart';

/// Contrat HTTP du reset (issue #381) : verbe/chemin/corps, statut 200 = succes,
/// erreurs traduites en [Result.failure] typé, appels NON authentifies.
void main() {
  HttpPasswordResetRepository build(
    http.Response Function(http.Request request) handler,
  ) =>
      HttpPasswordResetRepository(
        ApiTransport(
          MockClient((request) async => handler(request)),
          FakeTokenStore(accessToken: 'jwt'),
        ),
      );

  group('requestReset', () {
    test('POST /auth/forgot-password avec l\'email, sans auth -> Success',
        () async {
      late http.Request captured;
      final repo = build((r) {
        captured = r;
        return http.Response('', 200);
      });

      final result = await repo.requestReset('a@b.c');

      expect(result, isA<Success<void>>());
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/auth/forgot-password'));
      expect(jsonDecode(captured.body)['email'], 'a@b.c');
      // Anti-fuite : aucun jeton d'acces n'est envoye sur ce flux.
      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('erreur reseau/serveur -> Failure (aucun throw ne fuit)', () async {
      final repo = build((_) => http.Response('boom', 500));

      final result = await repo.requestReset('a@b.c');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).exception, isA<AppException>());
    });
  });

  group('confirmReset', () {
    test('POST /auth/reset-password avec token + newPassword -> Success',
        () async {
      late http.Request captured;
      final repo = build((r) {
        captured = r;
        return http.Response('', 200);
      });

      final result = await repo.confirmReset(
        token: 'tok',
        newPassword: 'NouveauMotDePasse1',
      );

      expect(result, isA<Success<void>>());
      expect(captured.url.path, endsWith('/auth/reset-password'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['token'], 'tok');
      expect(body['newPassword'], 'NouveauMotDePasse1');
    });

    test('jeton invalide (400) -> Failure typé', () async {
      final repo = build(
        (_) => http.Response(jsonEncode({'message': 'Lien invalide'}), 400),
      );

      final result = await repo.confirmReset(token: 'bad', newPassword: 'x');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).exception, isA<AppException>());
    });
  });
}
