import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/features/ai/application/get_ai_status_usecase.dart';
import 'package:cv_mobile/providers/ai_status_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetAiStatus extends Mock implements GetAiStatusUseCase {}

void main() {
  late _MockGetAiStatus getAiStatus;
  late AiStatusProvider provider;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getAiStatus = _MockGetAiStatus();
    provider = AiStatusProvider(getAiStatus: getAiStatus);
  });

  test('refresh charge le statut backend enrichi', () async {
    when(() => getAiStatus(any())).thenAnswer(
      (_) async => Result.success(
        AiStatus.fromJson({
          'available': false,
          'primaryProvider': 'primary',
          'primaryStatus': 'CIRCUIT_OPEN',
          'circuitBreakerState': 'OPEN',
          'fallbackAvailable': false,
          'fallbackInUse': false,
          'checkedAt': '2026-07-13T12:00:00Z',
          'lastError': {'type': 'AI_PROVIDER_DOWN'},
        }),
      ),
    );

    await provider.refresh();

    expect(provider.available, isFalse);
    expect(provider.status.circuitBreakerState, 'OPEN');
    expect(provider.status.lastErrorType, 'AI_PROVIDER_DOWN');
    expect(provider.unavailableReason, contains('temporairement'));
  });

  test('refresh conserve le dernier statut si le use case echoue', () async {
    when(() => getAiStatus(any())).thenAnswer(
      (_) async => const Result.failure(NetworkException()),
    );
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.refresh();

    expect(provider.status.primaryStatus, 'UNKNOWN');
    expect(provider.available, isTrue);
    expect(notifications, 1);
  });

  test(
      'recordError : une erreur sans delai ne doit pas effacer un backoff de quota actif',
      () {
    provider.recordError(const AiException(
        code: 'AI_QUOTA_EXCEEDED',
        message: 'quota',
        retryAfter: Duration(minutes: 10)));
    final backoff = provider.retryAfter;
    expect(backoff, isNotNull);

    // Erreur ulterieure SANS delai (ex. provider down) : ne doit PAS effacer le
    // backoff de quota encore actif.
    provider.recordError(
        const AiException(code: 'AI_PROVIDER_DOWN', message: 'down'));

    expect(provider.retryAfter, backoff,
        reason: 'le backoff de quota actif est preserve');
    expect(provider.unavailableReason, contains("Limite d'usage"));
  });
}
