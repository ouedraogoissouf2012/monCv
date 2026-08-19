import 'dart:convert';
import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/data/cv_network_codec.dart';
import 'package:cv_mobile/services/api/ai_http_client.dart';
import 'package:cv_mobile/services/api/cv_export_http_client.dart';
import 'package:cv_mobile/services/api/cv_http_client.dart';
import 'package:cv_mobile/services/api/cv_share_http_client.dart';
import 'package:cv_mobile/services/api/photo_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_client_test_harness.dart';

/// CV (CRUD/import), partage, export, IA et photo : delegation et erreurs.
void main() {
  group('CvHttpClient', () {
    final cvClient = CvHttpClient(
      headers: fakeHeaders,
      accessToken: () async => 'test-token',
    );

    test('getAllCvs GET /cvs et decode la liste', () async {
      final cvs = await withMockClient(
        () => cvClient.getAllCvs(),
        (_) => http.Response(jsonEncode([
              {'titre': 'A'}
            ]), 200),
      );

      expect(cvs.single.titre, 'A');
    });

    test('createCv POST (201) envoie le titre et decode la reponse', () async {
      late http.Request captured;
      final input = cvFromNetworkJson({'titre': 'Mon CV'});

      final created = await withMockClient(
        () => cvClient.createCv(input),
        (_) => http.Response(jsonEncode({'titre': 'Mon CV'}), 201),
        onRequest: (r) => captured = r,
      );

      expect(captured.method, 'POST');
      expect(jsonDecode(captured.body)['titre'], 'Mon CV');
      expect(created.titre, 'Mon CV');
    });

    test('createCv en erreur (400) leve via throwApiError', () async {
      final input = cvFromNetworkJson({'titre': 'X'});

      await expectLater(
        withMockClient(
          () => cvClient.createCv(input),
          (_) => http.Response(jsonEncode({'message': 'invalide'}), 400),
        ),
        throwsA(predicate((e) => e.toString().contains('invalide'))),
      );
    });

    test('importCv envoie un multipart POST /cvs/import', () async {
      late http.Request captured;

      final cv = await withMockClient(
        () => cvClient.importCv(Uint8List.fromList([1, 2, 3]), 'cv.pdf'),
        (_) => http.Response(jsonEncode({'titre': 'Importe'}), 201),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/cvs/import'));
      expect(
        captured.headers.values.any((v) => v.contains('multipart/form-data')),
        isTrue,
      );
      expect(cv.titre, 'Importe');
    });

    test('getAllCvs 401 leve une AuthException typee (M-9)', () async {
      await expectLater(
        withMockClient(
          () => cvClient.getAllCvs(),
          (_) => http.Response(jsonEncode({'message': 'expire'}), 401),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('importCv en erreur (400) leve une AppException typee (M-9)', () async {
      // Chemin multipart/streame : l'erreur doit rester typee, pas une Exception brute.
      await expectLater(
        withMockClient(
          () => cvClient.importCv(Uint8List.fromList([1]), 'cv.pdf'),
          (_) => http.Response(jsonEncode({'message': 'format invalide'}), 400),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('CvShareHttpClient', () {
    const shareClient = CvShareHttpClient(headers: fakeHeaders);

    test('generateShareLink POST /cvs/1/share', () async {
      late http.Request captured;

      await withMockClient(
        () => shareClient.generateShareLink(1),
        (_) => http.Response(
          jsonEncode({'titre': 'S', 'publicToken': 'tok'}),
          200,
        ),
        onRequest: (r) => captured = r,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/cvs/1/share'));
    });

    test('regenerateShareLink 404 leve NotFoundException', () async {
      await expectLater(
        withMockClient(
          () => shareClient.regenerateShareLink(9),
          (_) => http.Response(jsonEncode({'message': 'absent'}), 404),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('generateShareLink 401 leve une AuthException typee (M-9)', () async {
      await expectLater(
        withMockClient(
          () => shareClient.generateShareLink(1),
          (_) => http.Response(jsonEncode({'message': 'non autorise'}), 401),
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('CvExportHttpClient', () {
    test('downloadCvPdf GET /cvs/1/pdf?template=... retourne les octets',
        () async {
      late http.Request captured;
      const client = CvExportHttpClient(headers: fakeHeaders);

      final bytes = await withMockClient(
        () => client.downloadCvPdf(1, template: 'MODERNE'),
        (_) => http.Response.bytes([1, 2, 3], 200),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/cvs/1/pdf'));
      expect(captured.url.queryParameters['template'], 'MODERNE');
      expect(bytes, [1, 2, 3]);
    });

    test('downloadCvDocx 404 leve NotFoundException typee (M-9)', () async {
      const client = CvExportHttpClient(headers: fakeHeaders);
      await expectLater(
        withMockClient(
          () => client.downloadCvDocx(1),
          (_) => http.Response('introuvable', 404),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('AiHttpClient', () {
    test('getAiSuggestions POST /ai/suggest retourne la liste', () async {
      late http.Request captured;
      const client = AiHttpClient(headers: fakeHeaders);

      final suggestions = await withMockClient(
        () => client.getAiSuggestions(poste: 'Dev', consentAccepted: true),
        (_) => http.Response(
          jsonEncode({
            'suggestions': ['a', 'b']
          }),
          200,
        ),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/ai/suggest'));
      expect(suggestions, ['a', 'b']);
    });
  });

  group('PhotoHttpClient', () {
    test('uploadPhotoBytes envoie un multipart et retourne l\'URL', () async {
      late http.Request captured;
      final client = PhotoHttpClient(accessToken: () async => 'test-token');

      final url = await withMockClient(
        () => client.uploadPhotoBytes(
          Uint8List.fromList([9, 9]),
          'p.png',
          'image/png',
        ),
        (_) => http.Response(jsonEncode({'url': '/uploads/p.png'}), 200),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/uploads/photo'));
      expect(
        captured.headers.values.any((v) => v.contains('multipart/form-data')),
        isTrue,
      );
      expect(url, '/uploads/p.png');
    });

    test('uploadPhotoBytes en erreur leve une AppException typee (M-9)',
        () async {
      final client = PhotoHttpClient(accessToken: () async => 'test-token');
      await expectLater(
        withMockClient(
          () => client.uploadPhotoBytes(
            Uint8List.fromList([1]),
            'p.png',
            'image/png',
          ),
          (_) => http.Response(jsonEncode({'message': 'trop gros'}), 413),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
