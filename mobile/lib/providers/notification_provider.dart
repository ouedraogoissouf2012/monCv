import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';
import '../services/i_api_client.dart';

class NotificationProvider extends ChangeNotifier {
  final IApiClient api;
  NotificationProvider(this.api);

  NotificationPreferences value = const NotificationPreferences();
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      value = await api.getNotificationPreferences();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(NotificationPreferences next) async {
    final previous = value;
    value = next;
    notifyListeners();
    try {
      value = await api.updateNotificationPreferences(next);
    } catch (e) {
      value = previous;
      error = e.toString();
    }
    notifyListeners();
  }
}
