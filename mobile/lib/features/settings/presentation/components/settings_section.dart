import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/app_theme_extensions.dart';
import '../../../../core/design_system/tokens/app_radii.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';

/// Section de reglages : un titre discret suivi de son contenu (issue #250).
///
/// Structure reutilisable par tous les groupes de l'ecran profil/reglages
/// (informations, apparence, langue, notifications, confidentialite). Remplace
/// le `_SectionTitle` local du monolithe `profile_screen.dart`.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// Carte contenant une liste de tuiles de reglages, separees par un filet fin
/// (issue #250). Remplace le `_InfoCard` local du monolithe.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadii.xl,
        border: Border.all(
          color: context.colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: _withDividers(children)),
    );
  }

  /// Intercale un [Divider] entre chaque enfant (jamais en tete ni en pied).
  static List<Widget> _withDividers(List<Widget> children) {
    if (children.length <= 1) return children;
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        children[i],
      ],
    ];
  }
}
