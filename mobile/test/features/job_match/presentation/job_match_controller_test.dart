import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/match_job_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/job_match/domain/job_score_snapshot.dart';
import 'package:cv_mobile/features/job_match/presentation/job_match_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

void main() {
  late _MockAiRepo repo;

  // Horloge deterministe pour l'historique.
  DateTime fixedClock() => DateTime(2026, 1, 1, 12);

  JobMatchController controller({JobScoreHistory? history}) => JobMatchController(
        cvId: 42,
        matchJob: MatchJobUseCase(repo),
        clock: fixedClock,
        history: history,
      );

  setUp(() => repo = _MockAiRepo());

  const okReport = JobMatch(score: 78, aiGenerated: true);

  group('JobMatchController - validation offre (#245 G1)', () {
    test('offre < 20 caracteres -> invalide, canAnalyze faux', () {
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('trop court');
      expect(c.isJobDescriptionValid, isFalse);
      expect(c.canAnalyze, isFalse);
    });

    test('offre >= 20 + consentement -> canAnalyze vrai', () {
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');
      expect(c.isJobDescriptionValid, isTrue);
      expect(c.canAnalyze, isTrue);
    });

    test('sans consentement -> canAnalyze faux', () {
      final c = controller()
        ..setJobDescription('Une offre suffisamment longue pour analyse.');
      expect(c.canAnalyze, isFalse);
    });
  });

  group('JobMatchController - analyse (#245 G1)', () {
    test('offre invalide -> analyze() sans effet (pas d appel)', () async {
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('court');
      await c.analyze();
      verifyNever(() => repo.matchJob(any(), any()));
    });

    test('succes -> report typé + score ajoute a l historique', () async {
      when(() => repo.matchJob(42, any()))
          .thenAnswer((_) async => const Result.success(okReport));
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');

      await c.analyze();

      expect(c.report?.score, 78);
      expect(c.error, isNull);
      expect(c.loading, isFalse);
      expect(c.history, hasLength(1));
      expect(c.history.first.score, 78);
      expect(c.history.first.isRerun, isFalse);
    });

    test('re-analyse -> 2e entree marquee isRerun', () async {
      when(() => repo.matchJob(42, any()))
          .thenAnswer((_) async => const Result.success(okReport));
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');

      await c.analyze();
      await c.analyze();

      expect(c.history, hasLength(2));
      expect(c.history.first.isRerun, isTrue, reason: 'la plus recente');
      expect(c.history.last.isRerun, isFalse);
    });
  });

  group('JobMatchController - erreurs et retry (#245 G1)', () {
    test('erreur IA typee -> exposee + onAiError notifie', () async {
      const aiError =
          AiException(code: 'AI_PROVIDER_DOWN', message: 'indisponible');
      when(() => repo.matchJob(any(), any()))
          .thenAnswer((_) async => const Result.failure(aiError));
      AiException? received;
      final c = JobMatchController(
        cvId: 42,
        matchJob: MatchJobUseCase(repo),
        clock: fixedClock,
        onAiError: (e) => received = e,
      )
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');

      await c.analyze();

      expect(c.error, same(aiError));
      expect(received, same(aiError));
      expect(c.report, isNull);
    });

    test('retry apres echec : erreur effacee puis succes', () async {
      final answers = <Result<JobMatch>>[
        const Result.failure(NetworkException()),
        const Result.success(okReport),
      ];
      when(() => repo.matchJob(any(), any()))
          .thenAnswer((_) async => answers.removeAt(0));
      final c = controller()
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');

      await c.analyze();
      expect(c.error, isNotNull);

      await c.analyze();
      expect(c.error, isNull);
      expect(c.report?.score, 78);
    });
  });

  group('JobScoreHistory - borne (#245 G1)', () {
    test('limite a maxEntries, plus recent en tete', () {
      final h = JobScoreHistory(maxEntries: 3);
      for (var i = 1; i <= 5; i++) {
        h.record(i, DateTime(2026, 1, i));
      }
      expect(h.length, 3);
      expect(h.entries.first.score, 5, reason: 'dernier ajoute en tete');
      expect(h.entries.last.score, 3, reason: 'les 2 plus anciens evinces');
    });

    test('premiere entree isRerun faux, suivantes vrai', () {
      final h = JobScoreHistory();
      h.record(50, DateTime(2026));
      h.record(60, DateTime(2026, 1, 2));
      expect(h.entries.last.isRerun, isFalse);
      expect(h.entries.first.isRerun, isTrue);
    });
  });
}
