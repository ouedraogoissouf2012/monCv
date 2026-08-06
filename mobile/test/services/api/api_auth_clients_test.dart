import 'dart:convert';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/models/job_application.dart';
import 'package:cv_mobile/models/notification_preferences.dart';
import 'package:cv_mobile/services/api/auth_http_client.dart';
import 'package:cv_mobile/services/api/job_application_http_client.dart';
import 'package:cv_mobile/services/api/notification_http_client.dart';
import 'package:cv_mobile/services/api/user_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_client_test_harness.dart';

/// Auth, notifications, candidatures et profil : delegation et erreurs typees.
void main() {
  group('AuthHttpClient', () {
    test('login POST /auth/login, stocke les jetons et retourne AuthResponse',
        () async {
      late http.Request captured;
      String? storedAccess;
      final client = AuthHttpClient(
        headers: fakeHeaders,
        storeTokens: (a, r) async => storedAccess = a,
      );

      final auth = await withMockClient(
        () => client.login(email: 'a@b.c', password: 'pw'),
        (_) => http.Response(authResponseBody(), 200),
        onRequest: (r) => captured = r,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/auth/login'));
      expect(jsonDecode(captured.body)['email'], 'a@b.c');
      expect(auth.accessToken, 'acc');
      expect(storedAccess, 'acc');
    });

    test('login non-200 leve une Exception portant le message serveur',
        () async {
      final client = AuthHttpClient(
        headers: fakeHeaders,
        storeTokens: (_, __) async {},
      );

      await expectLater(
        withMockClient(
          () => client.login(email: 'a@b.c', password: 'bad'),
          (_) => http.Response(jsonEncode({'message': 'refuse'}), 401),
        ),
        throwsA(predicate((e) => e.toString().contains('refuse'))),
      );
    });

    test('register POST /auth/register (201)', () async {
      late http.Request captured;
      final client = AuthHttpClient(
        headers: fakeHeaders,
        storeTokens: (_, __) async {},
      );

      await withMockClient(
        () => client.register(email: 'a@b.c', password: 'pw'),
        (_) => http.Response(authResponseBody(), 201),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/auth/register'));
    });
  });

  group('NotificationHttpClient', () {
    test('getNotificationPreferences GET et parse la reponse', () async {
      const client = NotificationHttpClient(headers: fakeHeaders);

      final prefs = await withMockClient(
        () => client.getNotificationPreferences(),
        (_) => http.Response(jsonEncode({'staleCvEnabled': false}), 200),
      );

      expect(prefs.staleCvEnabled, isFalse);
    });

    test('updateNotificationPreferences PUT envoie le corps serialise',
        () async {
      late http.Request captured;
      const client = NotificationHttpClient(headers: fakeHeaders);

      await withMockClient(
        () => client.updateNotificationPreferences(
          const NotificationPreferences(cvViewsEnabled: false),
        ),
        (_) => http.Response(jsonEncode({'cvViewsEnabled': false}), 200),
        onRequest: (r) => captured = r,
      );

      expect(captured.method, 'PUT');
      expect(jsonDecode(captured.body)['cvViewsEnabled'], isFalse);
    });

    test('registerDeviceToken en erreur leve une AppException typee', () async {
      const client = NotificationHttpClient(headers: fakeHeaders);

      await expectLater(
        withMockClient(
          () => client.registerDeviceToken('t', 'android'),
          (_) => http.Response(jsonEncode({'message': 'boom'}), 500),
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('JobApplicationHttpClient', () {
    test('getJobApplications propage le filtre status en query', () async {
      late http.Request captured;
      const client = JobApplicationHttpClient(headers: fakeHeaders);

      final apps = await withMockClient(
        () => client.getJobApplications(status: JobApplicationStatus.sent),
        (_) => http.Response(
          jsonEncode([
            {'company': 'X', 'position': 'Dev', 'status': 'SENT'}
          ]),
          200,
        ),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/applications'));
      expect(captured.url.queryParameters['status'], 'SENT');
      expect(apps.single.company, 'X');
    });
  });

  group('UserHttpClient', () {
    test('getCurrentUser GET /users/me', () async {
      late http.Request captured;
      final client =
          UserHttpClient(headers: fakeHeaders, clearTokens: () async {});

      final user = await withMockClient(
        () => client.getCurrentUser(),
        (_) => http.Response(
          jsonEncode({'id': 1, 'email': 'a@b.c', 'role': 'USER'}),
          200,
        ),
        onRequest: (r) => captured = r,
      );

      expect(captured.url.path, endsWith('/users/me'));
      expect(user.email, 'a@b.c');
    });

    test('deleteAccount (204) purge les jetons locaux', () async {
      var cleared = false;
      final client = UserHttpClient(
        headers: fakeHeaders,
        clearTokens: () async => cleared = true,
      );

      await withMockClient(
        () => client.deleteAccount(),
        (_) => http.Response('', 204),
      );

      expect(cleared, isTrue);
    });
  });
}
