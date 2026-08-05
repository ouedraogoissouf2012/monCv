import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_typography.dart';
import 'auth_palette.dart';

/// Titre + sous-titre d'un ecran d'auth (issue #248, C4). Police de marque via
/// le design system. Partage entre login et register.
class AuthHeadline extends StatelessWidget {
  const AuthHeadline({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.display(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: AuthPalette.text,
                  height: 1.2,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: AuthPalette.muted,
                  fontWeight: FontWeight.w300)),
        ],
      );
}
