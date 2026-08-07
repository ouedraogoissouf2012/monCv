import '../../../core/error/error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../models/notification_preferences.dart';
import '../../../services/i_api_client.dart';
import '../domain/notification_settings_repository.dart';

/// Implementation HTTP de [NotificationSettingsRepository] (issue #258).
///
/// Enveloppe le client [IApiClient] et convertit ses exceptions typees en
/// [Result] via [FutureResultExtension.toResult]. Seule cette couche `data`
/// connait le transport ; la presentation ne le voit jamais.
class HttpNotificationSettingsRepository
    implements NotificationSettingsRepository {
  const HttpNotificationSettingsRepository(this._api);

  final IApiClient _api;

  @override
  Future<Result<NotificationPreferences>> getPreferences() =>
      _api.getNotificationPreferences().toResult();

  @override
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences next,
  ) =>
      _api.updateNotificationPreferences(next).toResult();
}
