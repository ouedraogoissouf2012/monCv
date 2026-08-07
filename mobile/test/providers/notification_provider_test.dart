import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/notifications/domain/notification_settings_repository.dart';
import 'package:cv_mobile/models/notification_preferences.dart';
import 'package:cv_mobile/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificationSettingsRepository {}

void main() {
  late _MockRepo repo;
  late NotificationProvider provider;

  setUp(() {
    repo = _MockRepo();
    provider = NotificationProvider(repo);
  });

  test('load succès applique les préférences serveur et purge le loading',
      () async {
    when(() => repo.getPreferences()).thenAnswer(
      (_) async => const Result.success(
        NotificationPreferences(staleCvEnabled: false),
      ),
    );

    await provider.load();

    expect(provider.value.staleCvEnabled, isFalse);
    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('load échec expose un message typé sans écraser la valeur', () async {
    when(() => repo.getPreferences())
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.load();

    expect(provider.error, isNotNull);
    expect(provider.value.staleCvEnabled, isTrue); // valeur par défaut conservée
    expect(provider.isLoading, isFalse);
  });

  test('update succès applique la valeur confirmée par le serveur', () async {
    const next = NotificationPreferences(cvViewsEnabled: false);
    when(() => repo.updatePreferences(next)).thenAnswer(
      (_) async => const Result.success(
        NotificationPreferences(cvViewsEnabled: false, aiTipsEnabled: false),
      ),
    );

    await provider.update(next);

    expect(provider.value.cvViewsEnabled, isFalse);
    expect(provider.value.aiTipsEnabled, isFalse); // echo serveur applique
  });

  test('update échec revient à la valeur précédente (rollback optimiste)',
      () async {
    const next = NotificationPreferences(staleCvEnabled: false);
    when(() => repo.updatePreferences(next))
        .thenAnswer((_) async => const Result.failure(ServerException()));

    await provider.update(next);

    // La valeur optimiste (staleCvEnabled=false) a ete annulee.
    expect(provider.value.staleCvEnabled, isTrue);
    expect(provider.error, isNotNull);
  });
}
