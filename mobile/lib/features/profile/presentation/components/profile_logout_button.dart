import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/app_theme_extensions.dart';
import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../l10n/app_localizations.dart';

/// Bouton de deconnexion pleine largeur (issue #250, E4).
///
/// Style avec le token `danger` du design system (le monolithe utilisait
/// `Colors.red` code en dur).
class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = context.colorTokens.danger;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.logout, color: danger),
      label: Text(
        AppLocalizations.of(context)!.logout,
        style: TextStyle(color: danger),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: danger),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
      ),
    );
  }
}
