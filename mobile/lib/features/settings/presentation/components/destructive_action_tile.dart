import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/app_theme_extensions.dart';
import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';

/// Taille d'icone de tete de tuile (colonne de gauche).
const double _kLeadingIconSize = 18;

/// Tuile d'action destructrice (issue #250) : suppression de compte, etc.
///
/// Utilise le token `danger` du design system (distinct de `ColorScheme.error`)
/// au lieu de `Colors.red` code en dur. Expose `Semantics(button: true)` pour
/// que l'action soit annoncee comme un bouton par les lecteurs d'ecran.
class DestructiveActionTile extends StatelessWidget {
  const DestructiveActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final danger = context.colorTokens.danger;
    // `button: true` annonce la tuile comme un bouton ; le libelle accessible
    // provient du Text (titre + sous-titre) — ne pas le dupliquer ici.
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.xl,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: _kLeadingIconSize, color: danger),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: danger,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: danger.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: danger),
            ],
          ),
        ),
      ),
    );
  }
}
