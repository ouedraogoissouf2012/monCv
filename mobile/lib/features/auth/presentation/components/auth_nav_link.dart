import 'package:flutter/material.dart';

import 'auth_palette.dart';

/// Lien de navigation bas de carte ("Deja un compte ? Se connecter") des ecrans
/// d'auth (issue #248, C4). Partage entre login et register.
class AuthNavLink extends StatelessWidget {
  const AuthNavLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$prompt ',
              style: const TextStyle(fontSize: 13, color: AuthPalette.muted)),
          GestureDetector(
            onTap: onTap,
            child: Text(action,
                style: const TextStyle(
                    fontSize: 13,
                    color: AuthPalette.blue,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
