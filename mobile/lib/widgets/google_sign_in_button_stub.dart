import 'package:flutter/widgets.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onCredential});

  final Future<void> Function(String credential) onCredential;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
