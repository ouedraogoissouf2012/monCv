import 'dart:async';

import 'package:cv_mobile/services/bounded_http_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final uri = Uri.parse('https://api.example.test/public/cv');

  test('lit une reponse bornee avec le type MIME attendu', () async {
    late http.Request captured;
    final reader = BoundedHttpReader(
      MockClient(
        (request) async {
          captured = request;
          return http.Response(
            '{"titre":"CV"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        },
      ),
    );

    final response = await reader.get(
      uri,
      maxBytes: 1024,
      timeout: const Duration(seconds: 1),
      expectedContentType: 'application/json',
      headers: const {'Authorization': 'Bearer test'},
    );

    expect(response.statusCode, 200);
    expect(response.body, '{"titre":"CV"}');
    expect(captured.headers['Authorization'], 'Bearer test');
  });

  test('rejette une longueur declaree ou diffusee trop grande', () async {
    final reader = BoundedHttpReader(
      MockClient(
        (_) async => http.Response(
          '12345',
          200,
          headers: {'content-type': 'application/pdf'},
        ),
      ),
    );

    expect(
      () => reader.get(
        uri,
        maxBytes: 4,
        timeout: const Duration(seconds: 1),
        expectedContentType: 'application/pdf',
      ),
      throwsA(isA<ResponseTooLargeException>()),
    );
  });

  test('rejette un type MIME inattendu et applique un timeout', () async {
    final wrongType = BoundedHttpReader(
      MockClient(
        (_) async => http.Response(
          '<html>erreur</html>',
          200,
          headers: {'content-type': 'text/html'},
        ),
      ),
    );
    expect(
      () => wrongType.get(
        uri,
        maxBytes: 1024,
        timeout: const Duration(seconds: 1),
        expectedContentType: 'application/pdf',
      ),
      throwsA(isA<UnexpectedContentTypeException>()),
    );

    final slow = BoundedHttpReader(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    expect(
      () => slow.get(
        uri,
        maxBytes: 1024,
        timeout: const Duration(milliseconds: 1),
        expectedContentType: 'application/json',
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
