import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/features/ai/application/enhance_cv_usecase.dart';
import 'package:cv_mobile/features/ai/application/generate_application_messages_usecase.dart';
import 'package:cv_mobile/features/ai/application/generate_resume_usecase.dart';
import 'package:cv_mobile/features/ai/application/get_ai_status_usecase.dart';
import 'package:cv_mobile/features/ai/application/match_job_usecase.dart';
import 'package:cv_mobile/features/ai/application/suggest_bullets_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/application_messages.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/models/ai_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepository extends Mock implements AiRepository {}

/// Chaque use case ne doit que transmettre au port avec les bons parametres et
/// propager le Result typé sans transformation.
void main() {
  late _MockAiRepository repo;

  setUp(() => repo = _MockAiRepository());

  test('EnhanceCvUseCase transmet cvId/level et propage le Result', () async {
    when(() => repo.enhanceCv(9, 'MAX', consentAccepted: true)).thenAnswer(
      (_) async => const Result.success(EnhancedCv(aiGenerated: true)),
    );

    final result = await EnhanceCvUseCase(repo)
        .call(const EnhanceCvParams(
            cvId: 9, level: 'MAX', consentAccepted: true));

    expect(result.getOrThrow().aiGenerated, isTrue);
    verify(() => repo.enhanceCv(9, 'MAX', consentAccepted: true)).called(1);
  });

  test('MatchJobUseCase transmet cvId/jobDescription', () async {
    when(() => repo.matchJob(3, 'Offre', consentAccepted: true))
        .thenAnswer((_) async => const Result.success(JobMatch(score: 70)));

    final result =
        await MatchJobUseCase(repo).call(const MatchJobParams(
      cvId: 3,
      jobDescription: 'Offre',
      consentAccepted: true,
    ));

    expect(result.getOrThrow().score, 70);
    verify(() => repo.matchJob(3, 'Offre', consentAccepted: true)).called(1);
  });

  test('GenerateApplicationMessagesUseCase transmet les 3 parametres', () async {
    when(() => repo.generateApplicationMessages(1, 'Offre', 'FORMAL'))
        .thenAnswer(
      (_) async => const Result.success(
        ApplicationMessages(coverLetter: 'lettre'),
      ),
    );

    final result = await GenerateApplicationMessagesUseCase(repo).call(
      const GenerateApplicationMessagesParams(
        cvId: 1,
        jobDescription: 'Offre',
        tone: 'FORMAL',
      ),
    );

    expect(result.getOrThrow().coverLetter, 'lettre');
    verify(() => repo.generateApplicationMessages(1, 'Offre', 'FORMAL'))
        .called(1);
  });

  test('GenerateResumeUseCase transmet les champs libres', () async {
    when(() => repo.generateResume('Dev', null, null))
        .thenAnswer((_) async => const Result.success('resume'));

    final result = await GenerateResumeUseCase(repo)
        .call(const GenerateResumeParams(titrePoste: 'Dev'));

    expect(result.getOrThrow(), 'resume');
    verify(() => repo.generateResume('Dev', null, null)).called(1);
  });

  test('SuggestBulletsUseCase transmet poste/entreprise/description', () async {
    when(() => repo.getSuggestions(
          poste: 'Dev',
          entreprise: 'ACME',
          description: null,
        )).thenAnswer(
      (_) async => const Result.success(['a', 'b']),
    );

    final result = await SuggestBulletsUseCase(repo).call(
      const SuggestBulletsParams(poste: 'Dev', entreprise: 'ACME'),
    );

    expect(result.getOrThrow(), ['a', 'b']);
  });

  test('SuggestBulletsUseCase propage un echec reseau sans le transformer',
      () async {
    when(() => repo.getSuggestions(
          poste: 'Dev',
          entreprise: null,
          description: null,
        )).thenAnswer((_) async => const Result.failure(NetworkException()));

    final result = await SuggestBulletsUseCase(repo)
        .call(const SuggestBulletsParams(poste: 'Dev'));

    expect(result.isFailure, isTrue);
    expect((result as Failure).exception, isA<NetworkException>());
  });

  test('SuggestBulletsUseCase propage une erreur IA typee du port', () async {
    when(() => repo.getSuggestions(
          poste: 'Dev',
          entreprise: null,
          description: null,
        )).thenAnswer((_) async => const Result.failure(
          AiException(code: 'AI_QUOTA_EXCEEDED', message: 'Quota IA atteint'),
        ));

    final result = await SuggestBulletsUseCase(repo)
        .call(const SuggestBulletsParams(poste: 'Dev'));

    expect((result as Failure).exception, isA<AiException>());
  });

  test('GetAiStatusUseCase delegue a getStatus', () async {
    when(() => repo.getStatus())
        .thenAnswer((_) async => const Result.success(AiStatus.unknown()));

    final result = await GetAiStatusUseCase(repo).call(const NoParams());

    expect(result.getOrThrow(), isA<AiStatus>());
    verify(() => repo.getStatus()).called(1);
  });

  test('un Result.failure du port est propage sans transformation', () async {
    when(() => repo.enhanceCv(1, 'MAX', consentAccepted: true)).thenAnswer(
      (_) async => const Result.failure(NotFoundException()),
    );

    final result = await EnhanceCvUseCase(repo).call(
        const EnhanceCvParams(cvId: 1, level: 'MAX', consentAccepted: true));

    expect(result, isA<Failure>());
  });
}
