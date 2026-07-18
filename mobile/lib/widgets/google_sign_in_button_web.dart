import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../services/google_auth_coordinator.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, required this.onCredential});

  final Future<void> Function(String credential) onCredential;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<String>? _subscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final coordinator = GoogleAuthCoordinator.instance;
    if (!coordinator.isConfigured) return;
    _subscription = coordinator.credentials.listen(widget.onCredential);
    coordinator.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return Center(
      child: web.renderButton(
        configuration: web.GSIButtonConfiguration(
          type: web.GSIButtonType.standard,
          theme: web.GSIButtonTheme.outline,
          size: web.GSIButtonSize.large,
          text: web.GSIButtonText.continueWith,
          shape: web.GSIButtonShape.rectangular,
          minimumWidth: 320,
          locale: 'fr',
        ),
      ),
    );
  }
}
