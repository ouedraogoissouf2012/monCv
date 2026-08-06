import 'dart:convert';

import '../../models/notification_preferences.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP des notifications : enregistrement d'appareils et preferences
/// (issue #258, ex-#237). Extrait de `ApiService`.
class NotificationHttpClient {
  const NotificationHttpClient({required this.headers});

  final HeaderFactory headers;

  Future<void> registerDeviceToken(String token, String platform) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
      headers: await headers(),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (response.statusCode != 204) {
      throwTypedError(response);
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    final request = http.Request(
      'DELETE',
      Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
    )
      ..headers.addAll(await headers())
      ..body = jsonEncode({'token': token});
    final response = await http.Response.fromStream(
        await request.send().timeout(http.requestTimeout));
    if (response.statusCode != 204) {
      throwTypedError(response);
    }
  }

  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return NotificationPreferences.fromJson(jsonDecode(response.body));
    }
    throwTypedError(response);
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences value,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
      headers: await headers(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 200) {
      return NotificationPreferences.fromJson(jsonDecode(response.body));
    }
    throwTypedError(response);
  }
}
