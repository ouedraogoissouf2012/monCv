import 'dart:io';
import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/multipart_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart';

import 'fake_token_store.dart';

MultipartTransport _transport(
  http.StreamedResponse Function(http.BaseRequest request) handler, {
  FakeTokenStore? tokens,
}) =>
    MultipartTransport(
      MockClient.streaming((request, bodyStream) async {
        // On draine le corps pour rester fidele au comportement d un vrai envoi.
        await bodyStream.bytesToString();
        return handler(request);
      }),
      tokens ?? FakeTokenStore(),
    );

http.StreamedResponse _json(String body, int status) => http.StreamedResponse(
      Stream.value(utf8Bytes(body)),
      status,
      headers: const {'content-type': 'application/json'},
    );

Uint8List utf8Bytes(String value) => Uint8List.fromList(value.codeUnits);

void main() {
  test('envoie les octets sous le champ file avec Authorization', () async {
    late http.BaseRequest captured;
    final transport = _transport(
      (request) {
        captured = request;
        return _json('{"url":"/uploads/photos/x.jpg"}', 200);
      },
      tokens: FakeTokenStore(accessToken: 'jwt-9'),
    );

    final result = await transport.uploadJsonObject(
      path: '/uploads/photo',
      payload: BytesPayload(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    expect(result['url'], '/uploads/photos/x.jpg');
    expect(captured.method, 'POST');
    expect(captured.url.path, endsWith('/uploads/photo'));
    expect(captured.headers['Authorization'], 'Bearer jwt-9');
    expect(captured, isA<http.MultipartRequest>());
    expect((captured as http.MultipartRequest).files.single.field, 'file');
  });

  test('FilePathPayload et BytesPayload produisent le meme champ', () async {
    final tmp = File(
      '${Directory.systemTemp.path}/moncv_multipart_test.bin',
    )..writeAsBytesSync([9, 9, 9]);
    addTearDown(() => tmp.existsSync() ? tmp.deleteSync() : null);

    final captured = <http.MultipartRequest>[];
    final transport = _transport((request) {
      captured.add(request as http.MultipartRequest);
      return _json('{"ok":true}', 200);
    });

    await transport.uploadJsonObject(
      path: '/cvs/import',
      payload: FilePathPayload(tmp.path),
    );
    await transport.uploadJsonObject(
      path: '/cvs/import',
      payload: BytesPayload(
        bytes: Uint8List.fromList([9, 9, 9]),
        filename: 'cv.pdf',
        contentType: MediaType('application', 'pdf'),
      ),
    );

    expect(captured, hasLength(2));
    expect(captured[0].files.single.field, 'file');
    expect(captured[1].files.single.field, 'file');
  });

  test('omet Authorization quand withAuth est false', () async {
    late http.BaseRequest captured;
    final transport = _transport(
      (request) {
        captured = request;
        return _json('{}', 200);
      },
      tokens: FakeTokenStore(accessToken: 'jwt-9'),
    );

    await transport.uploadJsonObject(
      path: '/uploads/photo',
      withAuth: false,
      payload: BytesPayload(
        bytes: Uint8List.fromList([1]),
        filename: 'p.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    expect(captured.headers.containsKey('Authorization'), isFalse);
  });

  test('un status non-2xx est traduit en AppException', () async {
    final transport = _transport((_) => _json('{"message":"trop gros"}', 413));

    await expectLater(
      transport.uploadJsonObject(
        path: '/uploads/photo',
        payload: BytesPayload(
          bytes: Uint8List.fromList([1]),
          filename: 'p.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
      throwsA(isA<AppException>()),
    );
  });
}
