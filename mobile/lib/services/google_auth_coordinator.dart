import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class GoogleAuthCoordinator {
  GoogleAuthCoordinator._();

  static final instance = GoogleAuthCoordinator._();
  final _credentials = StreamController<String>.broadcast();
  Future<void>? _initialization;

  Stream<String> get credentials => _credentials.stream;
  bool get isConfigured => googleClientId.isNotEmpty;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!isConfigured) return;
    final signIn = GoogleSignIn.instance;
    await signIn.initialize(clientId: googleClientId);
    signIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final idToken = event.user.authentication.idToken;
        if (idToken != null && idToken.isNotEmpty) _credentials.add(idToken);
      }
    });
  }
}
