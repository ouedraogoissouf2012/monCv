import 'dart:io';
import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/multipart_transport.dart';
import 'package:cv_mobile/core/network/session_refresher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart';

import 'fake_token_store.dart';

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

  test('un 401 authentifie declenche un refresh puis rejoue l upload (M-7)',
      () async {
    final tokens = FakeTokenStore(accessToken: 'expired', refreshToken: 'r');
    final sent = <String?>[];
    var calls = 0;
    final refresher = _SpyRefresher(() async {
      await tokens.save(accessToken: 'fresh', refreshToken: 'r2');
      return true;
    });
    final transport = MultipartTransport(
      MockClient.streaming((request, bodyStream) async {
        await bodyStream.bytesToString();
        sent.add(request.headers['Authorization']);
        calls++;
        return _json('{"ok":true}', calls == 1 ? 401 : 200);
      }),
      tokens,
      refresher: refresher,
    );

    final result = await transport.uploadJsonObject(
      path: '/uploads/photo',
      payload: BytesPayload(
        bytes: Uint8List.fromList([1]),
        filename: 'p.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    expect(result['ok'], true);
    expect(refresher.calls, 1);
    expect(calls, 2, reason: 'upload initial + un rejeu');
    expect(sent, ['Bearer expired', 'Bearer fresh'],
        reason: 'le rejeu porte le jeton rafraichi');
  });

  test('refresh impossible sur 401 -> AppException propagee', () async {
    final refresher = _SpyRefresher(() async => false);
    final transport = MultipartTransport(
      MockClient.streaming((request, bodyStream) async {
        await bodyStream.bytesToString();
        return _json('{"message":"expire"}', 401);
      }),
      FakeTokenStore(accessToken: 'expired', refreshToken: 'r'),
      refresher: refresher,
    );

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
    expect(refresher.calls, 1);
  });
}
