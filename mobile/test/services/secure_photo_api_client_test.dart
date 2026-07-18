import 'package:cv_mobile/services/secure_photo_api_client.dart';
import 'package:cv_mobile/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const filename = '123e4567-e89b-12d3-a456-426614174000.jpg';
  const publicToken = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('authentifie uniquement le chargement de la photo du proprietaire',
      () async {
    late http.Request captured;
    final client = SecurePhotoApiClient(
      MockClient((request) async {
        captured = request;
        return http.Response.bytes(
          const [0xFF, 0xD8, 0xFF, 0x00],
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }),
    );

    final bytes = await client.load(
      '${ApiConstants.baseUrl}/uploads/photos/$filename',
      accessToken: 'access-token',
    );

    expect(bytes, const [0xFF, 0xD8, 0xFF, 0x00]);
    expect(captured.headers['Authorization'], 'Bearer access-token');
    expect(captured.headers['Accept'], 'image/jpeg');
  });

  test('charge la photo publique sans divulguer le jeton JWT', () async {
    late http.Request captured;
    final client = SecurePhotoApiClient(
      MockClient((request) async {
        captured = request;
        return http.Response.bytes(
          const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          200,
          headers: {'content-type': 'image/png'},
        );
      }),
    );

    final bytes = await client.load(
      '${ApiConstants.baseUrl}/cvs/public/$publicToken/photo',
      accessToken: 'must-not-be-used',
    );

    expect(bytes, isNotNull);
    expect(captured.headers, isNot(contains('Authorization')));
    expect(captured.headers['Accept'], 'image/');
  });

  test('rejette origine, traversal, query et nom non opaque avant le reseau',
      () async {
    var calls = 0;
    final client = SecurePhotoApiClient(
      MockClient((_) async {
        calls++;
        return http.Response('', 500);
      }),
    );

    final invalidUrls = [
      'https://tracker.example/photos/$filename',
      '${ApiConstants.baseUrl}/uploads/photos/../secret.jpg',
      '${ApiConstants.baseUrl}/uploads/photos/$filename?tracking=1',
      '${ApiConstants.baseUrl}/uploads/photos/photo.jpg',
    ];
    for (final url in invalidUrls) {
      await expectLater(
        client.load(url, accessToken: 'token'),
        throwsFormatException,
      );
    }
    expect(calls, 0);
  });

  test('ignore un corps dont la signature ne correspond pas au MIME', () async {
    final client = SecurePhotoApiClient(
      MockClient(
        (_) async => http.Response.bytes(
          '<script>'.codeUnits,
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      ),
    );

    expect(
      await client.load(
        '${ApiConstants.baseUrl}/uploads/photos/$filename',
        accessToken: 'token',
      ),
      isNull,
    );
  });
}
