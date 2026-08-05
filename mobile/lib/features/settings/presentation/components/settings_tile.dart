import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/app_theme_extensions.dart';
import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';

/// Taille d'icone de tete de tuile (colonne de gauche).
const double _kLeadingIconSize = 18;

/// Tuile de reglages a deux lignes (issue #250).
///
/// Deux variantes partageant la meme structure (icone + deux lignes de texte +
/// chevron optionnel), seule l'emphase change :
/// - constructeur par defaut : **action** — titre en avant, sous-titre discret,
///   chevron si [onTap] est fourni (ex. « Exporter mes donnees »).
/// - [SettingsTile.info] : **information** — libelle discret au-dessus de la
///   valeur mise en avant (ex. « Nom complet » / « John Doe »).
///
/// Remplace les `_ActionRow` / `_InfoRow` locaux du monolithe.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  }) : _emphasizeTop = true;

  const SettingsTile.info({
    super.key,
    required this.icon,
    required String label,
    required String value,
  })  : title = label,
        subtitle = value,
        onTap = null,
        _emphasizeTop = false;

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Vrai si la ligne du haut est mise en avant (variante action).
  final bool _emphasizeTop;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: _kLeadingIconSize, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _texts(context)),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colors.onSurface.withValues(alpha: 0.35),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.xl,
      child: content,
    );
  }

  Widget _texts(BuildContext context) {
    final emphasized = context.textStyles.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final muted = context.textStyles.labelSmall?.copyWith(
      color: context.colors.onSurface.withValues(alpha: 0.55),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _emphasizeTop ? emphasized : muted),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: _emphasizeTop ? muted : emphasized),
        ],
      ],
    );
  }
}
