import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/data/ai_remote_data_source.dart';
import 'package:cv_mobile/features/ai/data/ai_repository_impl.dart';
import 'package:cv_mobile/features/ai/domain/entities/application_messages.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/models/ai_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AiRemoteDataSource {}

/// Le repository est l'unique frontiere exception -> Result pour l'IA.
void main() {
  late _MockDataSource dataSource;
  late HttpAiRepository repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = HttpAiRepository(dataSource);
  });

  test('succes du data source -> Result.success typé', () async {
    when(() => dataSource.enhanceCv(1, 'MAX', consentAccepted: true))
        .thenAnswer((_) async => const EnhancedCv(aiGenerated: true));

    final result = await repository.enhanceCv(1, 'MAX', consentAccepted: true);

    expect(result, isA<Success<EnhancedCv>>());
    expect(result.getOrThrow().aiGenerated, isTrue);
  });

  test('AppException du data source -> Result.failure', () async {
    when(() => dataSource.matchJob(1, 'x', consentAccepted: true))
        .thenThrow(const NotFoundException());

    final result = await repository.matchJob(1, 'x', consentAccepted: true);

    expect(result, isA<Failure>());
    expect((result as Failure).exception, isA<NotFoundException>());
  });

  test('AiException est propagee telle quelle dans Result.failure', () async {
    when(() => dataSource.enhanceCv(1, 'MAX', consentAccepted: true)).thenThrow(
      const AiException(code: 'AI_TIMEOUT', message: 'timeout'),
    );

    final result = await repository.enhanceCv(1, 'MAX', consentAccepted: true);

    expect((result as Failure).exception, isA<AiException>());
  });

  test('exception non typee -> Result.failure via ErrorMapper', () async {
    when(() => dataSource.generateResume(any(), any(), any()))
        .thenThrow(Exception('boom'));

    final result = await repository.generateResume('a', 'b', 'c');

    expect(result, isA<Failure>());
    expect((result as Failure).exception, isA<AppException>());
  });

  test('matchJob succes -> Result.success<JobMatch>', () async {
    when(() => dataSource.matchJob(1, 'x', consentAccepted: true))
        .thenAnswer((_) async => const JobMatch(score: 42));
    final result = await repository.matchJob(1, 'x', consentAccepted: true);
    expect(result.getOrThrow().score, 42);
  });

  test('generateApplicationMessages succes -> Result.success', () async {
    when(() => dataSource.generateApplicationMessages(1, 'x', 'FORMAL'))
        .thenAnswer(
      (_) async => const ApplicationMessages(coverLetter: 'l'),
    );
    final result =
        await repository.generateApplicationMessages(1, 'x', 'FORMAL');
    expect(result.getOrThrow().coverLetter, 'l');
  });

  test('generateResume succes -> Result.success<String>', () async {
    when(() => dataSource.generateResume('a', 'b', 'c'))
        .thenAnswer((_) async => 'resume');
    final result = await repository.generateResume('a', 'b', 'c');
    expect(result.getOrThrow(), 'resume');
  });

  test('getSuggestions succes -> Result.success<List>', () async {
    when(() => dataSource.getSuggestions(
          poste: 'Dev',
          entreprise: null,
          description: null,
        )).thenAnswer((_) async => ['a']);
    final result = await repository.getSuggestions(poste: 'Dev');
    expect(result.getOrThrow(), ['a']);
  });

  test('getStatus succes -> Result.success<AiStatus>', () async {
    when(() => dataSource.getStatus())
        .thenAnswer((_) async => const AiStatus.unknown());
    final result = await repository.getStatus();
    expect(result.getOrThrow(), isA<AiStatus>());
  });
}
