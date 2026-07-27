import 'dart:convert';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/network/api_transport.dart';
import 'package:cv_mobile/features/ai/data/ai_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../core/network/fake_token_store.dart';
import 'fixtures/ai_fixtures.dart';

/// Tests de contrat : le nouveau data source doit produire les MEMES requetes
/// que l'ancien ApiService (verbe, chemin, corps) et retourner des entités
/// typees — aucun Map ne sort.
///
/// NB : les endpoints AI de l'ancien ApiService utilisent les fonctions HTTP
/// top-level de `http_timeout.dart` (et non le `http.Client` injecte), donc ils
/// ne sont PAS caracterisables par injection de MockClient. Ce fichier est donc
/// le filet de contrat de reference : chaque corps de requete reproduit a
/// l'octet pres celui d'ApiService — enhance-cv (api_service.dart:599-603),
/// match-job (654-658), application-messages (677-682), generate-resume
/// (635-640), suggest (503-509), status GET (695). Le mapping d'erreurs passe
/// par le meme ErrorMapper que l'ancien `_throwTypedError`.
void main() {
  HttpAiRemoteDataSource build(
    http.Response Function(http.Request request) handler,
  ) =>
      HttpAiRemoteDataSource(
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

  group('requetes identiques a ApiService', () {
    test('enhanceCv : POST /ai/enhance-cv + aiConsentAccepted', () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json(enhanceCvResponseJson, 200);
      });

      await ds.enhanceCv(42, 'MAX');

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/ai/enhance-cv'));
      expect(jsonDecode(captured.body), {
        'cvId': 42,
        'level': 'MAX',
        'aiConsentAccepted': true,
      });
    });

    test('matchJob : POST /ai/match-job + aiConsentAccepted', () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json(jobMatchResponseJson, 200);
      });

      await ds.matchJob(7, 'Dev Flutter');

      expect(captured.url.path, endsWith('/ai/match-job'));
      expect(jsonDecode(captured.body), {
        'cvId': 7,
        'jobDescription': 'Dev Flutter',
        'aiConsentAccepted': true,
      });
    });

    test('generateApplicationMessages : POST /ai/application-messages',
        () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json(applicationMessagesResponseJson, 200);
      });

      await ds.generateApplicationMessages(3, 'Offre', 'FORMAL');

      expect(captured.url.path, endsWith('/ai/application-messages'));
      expect(jsonDecode(captured.body), {
        'cvId': 3,
        'jobDescription': 'Offre',
        'tone': 'FORMAL',
        'aiConsentAccepted': true,
      });
    });

    test('generateResume : POST + null converti en chaine vide', () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json({'resume': 'ok'}, 200);
      });

      final resume = await ds.generateResume('Dev', null, null);

      expect(captured.url.path, endsWith('/ai/generate-resume'));
      expect(jsonDecode(captured.body), {
        'titrePoste': 'Dev',
        'competences': '',
        'experience': '',
        'aiConsentAccepted': true,
      });
      expect(resume, 'ok');
    });

    test('getSuggestions : POST /ai/suggest, omet les champs vides', () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json({
          'suggestions': ['a', 'b'],
        }, 200);
      });

      final result = await ds.getSuggestions(poste: 'Dev', entreprise: '');

      expect(captured.url.path, endsWith('/ai/suggest'));
      expect(jsonDecode(captured.body), {'poste': 'Dev'});
      expect(result, ['a', 'b']);
    });

    test('getStatus : GET /ai/status', () async {
      late http.Request captured;
      final ds = build((request) {
        captured = request;
        return json({'available': true}, 200);
      });

      await ds.getStatus();

      expect(captured.method, 'GET');
      expect(captured.url.path, endsWith('/ai/status'));
    });
  });

  group('retourne des entités typees (aucun Map ne sort)', () {
    test('enhanceCv mappe tous les champs imbriques', () async {
      final ds = build((_) => json(enhanceCvResponseJson, 200));
      final cv = await ds.enhanceCv(1, 'MAX');

      expect(cv.titrePoste, 'Developpeur Flutter');
      expect(cv.aiGenerated, isTrue);
      expect(cv.correctionCount, 3);
      expect(cv.experiences.single.poste, 'Dev');
      expect(cv.skills.single.niveau, 5);
      expect(cv.certifications.single.organisme, 'Amazon');
      expect(cv.warnings, ['Verifier les dates']);
      expect(cv.level, 'MAX');
    });

    test('matchJob mappe categories et recommandations', () async {
      final ds = build((_) => json(jobMatchResponseJson, 200));
      final match = await ds.matchJob(1, 'x');

      expect(match.score, 82);
      expect(match.categories.single.label, 'Competences');
      expect(match.categories.single.evidence, ['Flutter']);
      expect(match.prioritizedRecommendations.single.priority, 1);
      expect(match.formatChecks.single.severity, 'WARNING');
      expect(match.optimizedResume, 'Resume optimise.');
    });

    test('generateApplicationMessages mappe les 4 canaux', () async {
      final ds = build((_) => json(applicationMessagesResponseJson, 200));
      final messages = await ds.generateApplicationMessages(1, 'x', 'FORMAL');

      expect(messages.coverLetter, 'Lettre de motivation.');
      expect(messages.email, 'Email de candidature.');
      expect(messages.linkedIn, 'Message LinkedIn.');
      expect(messages.whatsApp, 'Message WhatsApp.');
    });
  });

  group('mapping d erreurs identique', () {
    test('enhanceCv 404 -> NotFoundException', () async {
      final ds = build((_) => json({'message': 'x'}, 404));
      await expectLater(ds.enhanceCv(1, 'MAX'), throwsA(isA<NotFoundException>()));
    });

    test('matchJob 502 AI_QUOTA_EXCEEDED -> AiException', () async {
      final ds = build(
        (_) => json({
          'code': 'AI_QUOTA_EXCEEDED',
          'details': {'retryAfter': 30},
        }, 502),
      );
      await expectLater(ds.matchJob(1, 'x'), throwsA(isA<AiException>()));
    });
  });
}
