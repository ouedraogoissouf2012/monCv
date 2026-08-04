import 'dart:convert';

import 'package:cv_mobile/core/network/api_transport.dart';
import 'package:cv_mobile/features/applications/data/application_remote_data_source.dart';
import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../core/network/fake_token_store.dart';

/// Tests de contrat du data source candidatures (#246 A2) : verbe, chemin,
/// corps et query identiques a l'ancien ApiService ; retourne des entités
/// typees (aucun Map ne sort).
void main() {
  HttpApplicationRemoteDataSource build(
    http.Response Function(http.Request request) handler,
  ) =>
      HttpApplicationRemoteDataSource(
        ApiTransport(
          MockClient((request) async => handler(request)),
          FakeTokenStore(accessToken: 'jwt'),
        ),
      );

  http.Response json(Object body, int status) => http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  const sampleJson = {
    'id': 7,
    'company': 'Acme',
    'position': 'Dev',
    'status': 'INTERVIEW',
    'offerUrl': 'https://acme.example/job',
    'nextFollowUp': '2026-06-20',
  };

  group('list', () {
    test('GET /applications sans filtre -> entités typees', () async {
      late http.Request captured;
      final ds = build((r) {
        captured = r;
        return json([sampleJson], 200);
      });

      final result = await ds.list();

      expect(captured.method, 'GET');
      expect(captured.url.path, endsWith('/applications'));
      expect(captured.url.queryParameters, isEmpty);
      expect(result, hasLength(1));
      expect(result.first, isA<JobApplication>());
      expect(result.first.status, JobApplicationStatus.interview);
      expect(result.first.company, 'Acme');
    });

    test('GET /applications?status=SENT quand filtre fourni', () async {
      late http.Request captured;
      final ds = build((r) {
        captured = r;
        return json([], 200);
      });

      await ds.list(status: JobApplicationStatus.sent);

      expect(captured.url.queryParameters['status'], 'SENT');
    });
  });

  group('create', () {
    test('POST /applications avec le corps serialise', () async {
      late http.Request captured;
      final ds = build((r) {
        captured = r;
        return json(sampleJson, 201);
      });

      final created = await ds.create(const JobApplication(
        company: 'Acme',
        position: 'Dev',
        status: JobApplicationStatus.sent,
      ));

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/applications'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['company'], 'Acme');
      expect(body['status'], 'SENT');
      expect(created.id, 7);
    });
  });

  group('update', () {
    test('PUT /applications/{id}', () async {
      late http.Request captured;
      final ds = build((r) {
        captured = r;
        return json(sampleJson, 200);
      });

      await ds.update(const JobApplication(
        id: 7,
        company: 'Acme',
        position: 'Dev',
      ));

      expect(captured.method, 'PUT');
      expect(captured.url.path, endsWith('/applications/7'));
    });
  });

  group('delete', () {
    test('DELETE /applications/{id}', () async {
      late http.Request captured;
      final ds = build((r) {
        captured = r;
        return http.Response('', 204);
      });

      await ds.delete(7);

      expect(captured.method, 'DELETE');
      expect(captured.url.path, endsWith('/applications/7'));
    });
  });
}
