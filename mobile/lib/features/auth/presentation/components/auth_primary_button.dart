import 'package:flutter/material.dart';

import 'auth_palette.dart';

/// Bouton principal (submit) des ecrans d'auth (issue #248, C4).
///
/// Affiche un spinner pendant [loading] et est desactive dans ce cas. Partage
/// entre login et register.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthPalette.blue,
          foregroundColor: AuthPalette.white,
          disabledBackgroundColor: AuthPalette.blue.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AuthPalette.white)))
            : Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3)),
      ),
    );
  }
}
