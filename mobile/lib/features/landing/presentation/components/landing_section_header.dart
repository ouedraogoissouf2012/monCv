import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../utils/app_colors.dart';

/// En-tete centre d'une section marketing : titre + sous-titre optionnel
/// (issue #251).
///
/// Factorise le motif « gros titre + sous-titre discret » repete par les
/// sections features / preview / how-it-works / CTA du monolithe. Utilise la
/// police de corps du design system ([AppTypography.fontFamilyBody]) — aucune
/// famille en dur. [onColor] adapte les couleurs pour un fond colore (CTA).
class LandingSectionHeader extends StatelessWidget {
  const LandingSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onColor = false,
  });

  final String title;
  final String? subtitle;
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamilyBody,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: onColor ? Colors.white : null,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamilyBody,
              fontSize: 14,
              color: onColor
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.neutral450,
            ),
          ),
        ],
      ],
    );
  }
}
