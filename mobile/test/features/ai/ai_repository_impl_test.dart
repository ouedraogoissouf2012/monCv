import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/data/ai_remote_data_source.dart';
import 'package:cv_mobile/features/ai/data/ai_repository_impl.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
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
    when(() => dataSource.enhanceCv(1, 'MAX'))
        .thenAnswer((_) async => const EnhancedCv(aiGenerated: true));

    final result = await repository.enhanceCv(1, 'MAX');

    expect(result, isA<Success<EnhancedCv>>());
    expect(result.getOrThrow().aiGenerated, isTrue);
  });

  test('AppException du data source -> Result.failure', () async {
    when(() => dataSource.matchJob(1, 'x'))
        .thenThrow(const NotFoundException());

    final result = await repository.matchJob(1, 'x');

    expect(result, isA<Failure>());
    expect((result as Failure).exception, isA<NotFoundException>());
  });

  test('AiException est propagee telle quelle dans Result.failure', () async {
    when(() => dataSource.enhanceCv(1, 'MAX')).thenThrow(
      const AiException(code: 'AI_TIMEOUT', message: 'timeout'),
    );

    final result = await repository.enhanceCv(1, 'MAX');

    expect((result as Failure).exception, isA<AiException>());
  });

  test('exception non typee -> Result.failure via ErrorMapper', () async {
    when(() => dataSource.generateResume(any(), any(), any()))
        .thenThrow(Exception('boom'));

    final result = await repository.generateResume('a', 'b', 'c');

    expect(result, isA<Failure>());
    expect((result as Failure).exception, isA<AppException>());
  });
}
