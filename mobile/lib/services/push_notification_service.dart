import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'i_api_client.dart';

class PushNotificationService {
  final IApiClient api;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _openSubscription;
  bool _initialized = false;

  PushNotificationService(this.api);

  bool get available => Firebase.apps.isNotEmpty && !kIsWeb;

  Future<void> initialize(GoRouter router) async {
    if (_initialized || !available) return;
    _initialized = true;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _register(token);
    _tokenSubscription = messaging.onTokenRefresh.listen(_register);
    _openSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _open(router, message));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(router, initial);
  }

  Future<void> _register(String token) =>
      api.registerDeviceToken(token, Platform.isIOS ? 'ios' : 'android');

  Future<void> deactivate() async {
    if (!_initialized) return;
    if (available) await FirebaseMessaging.instance.deleteToken();
    await _tokenSubscription?.cancel();
    await _openSubscription?.cancel();
    _tokenSubscription = null;
    _openSubscription = null;
    _initialized = false;
  }

  void _open(GoRouter router, RemoteMessage message) {
    final route = message.data['route'];
    final cvId = message.data['cvId'];
    if (route is String &&
        (route.startsWith('/cvs/') || route == '/applications')) {
      router.go(route);
    } else if (cvId != null) {
      router.go('/cvs/$cvId');
    }
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _openSubscription?.cancel();
  }
}
