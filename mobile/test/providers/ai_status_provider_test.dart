import 'package:cv_mobile/providers/ai_status_provider.dart';
import 'package:cv_mobile/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService api;
  late AiStatusProvider provider;

  setUp(() {
    api = MockApiService();
    provider = AiStatusProvider(api: api);
  });

  test('refresh charge le statut backend enrichi', () async {
    when(() => api.getAiStatus()).thenAnswer(
      (_) async => AiStatus.fromJson({
        'available': false,
        'primaryProvider': 'deepseek',
        'primaryStatus': 'CIRCUIT_OPEN',
        'circuitBreakerState': 'OPEN',
        'fallbackAvailable': false,
        'fallbackInUse': false,
        'checkedAt': '2026-07-13T12:00:00Z',
        'lastError': {'type': 'AI_PROVIDER_DOWN'},
      }),
    );

    await provider.refresh();

    expect(provider.available, isFalse);
    expect(provider.status.circuitBreakerState, 'OPEN');
    expect(provider.status.lastErrorType, 'AI_PROVIDER_DOWN');
    expect(provider.unavailableReason, contains('temporairement'));
  });

  test('refresh conserve le dernier statut si le endpoint echoue', () async {
    when(() => api.getAiStatus()).thenThrow(Exception('network down'));
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.refresh();

    expect(provider.status.primaryStatus, 'UNKNOWN');
    expect(provider.available, isTrue);
    expect(notifications, 1);
  });
}
