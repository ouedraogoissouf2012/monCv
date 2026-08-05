import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_typography.dart';
import 'auth_palette.dart';

/// Logo "MonCV" (icone + wordmark) des ecrans d'auth (issue #248, C4).
/// Extrait du code duplique login/register. Police de marque via le design
/// system (`AppTypography.display`), aucune police en dur.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AuthPalette.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description_outlined,
              size: 20, color: AuthPalette.white),
        ),
        const SizedBox(width: 10),
        Text('MonCV',
            style: AppTypography.display(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AuthPalette.text)),
      ],
    );
  }
}
