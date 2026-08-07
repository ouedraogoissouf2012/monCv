import 'package:flutter/foundation.dart';

import '../core/error/result.dart';
import '../features/notifications/domain/notification_settings_repository.dart';
import '../models/notification_preferences.dart';

/// Etat des preferences de notification.
///
/// Depend du port [NotificationSettingsRepository] (issue #258) et non plus du
/// transport reseau : la presentation ne connait plus `IApiClient`. Les erreurs
/// remontent typees ([AppException.message]) au lieu d'un `toString()` brut.
class NotificationProvider extends ChangeNotifier {
  final NotificationSettingsRepository repository;
  NotificationProvider(this.repository);

  NotificationPreferences value = const NotificationPreferences();
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    switch (await repository.getPreferences()) {
      case Success(:final data):
        value = data;
      case Failure(:final exception):
        error = exception.message;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> update(NotificationPreferences next) async {
    final previous = value;
    value = next;
    notifyListeners();
    switch (await repository.updatePreferences(next)) {
      case Success(:final data):
        value = data;
      case Failure(:final exception):
        value = previous;
        error = exception.message;
    }
    notifyListeners();
  }
}
