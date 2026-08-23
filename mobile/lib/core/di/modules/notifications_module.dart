import 'package:get_it/get_it.dart';

import '../../../features/notifications/data/http_notification_settings_repository.dart';
import '../../../features/notifications/domain/notification_settings_repository.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/i_api_client.dart';
import '../../../services/push_notification_service.dart';

/// Notifications : preferences de l'utilisateur et envoi push.
void registerNotificationsModule(GetIt sl) {
  sl.registerLazySingleton<NotificationSettingsRepository>(
    () => HttpNotificationSettingsRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(sl<IApiClient>()));
  sl.registerFactory<NotificationProvider>(
      () => NotificationProvider(sl<NotificationSettingsRepository>()));
}
