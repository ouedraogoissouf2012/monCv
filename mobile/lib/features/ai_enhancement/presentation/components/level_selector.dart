import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../domain/enhancement_level.dart';

/// Selecteur des 3 niveaux d'amelioration IA (LITE / MEDIUM / MAX) — issue #244.
///
/// Extrait de `_LevelInfo` + `_LevelTile`. Fonde sur l'enum [EnhancementLevel]
/// (plus de chaines magiques). [enabled] a false grise la selection (mode
/// relecture ou chargement).
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final EnhancementLevel selected;
  final ValueChanged<EnhancementLevel> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final level in EnhancementLevel.values)
          _LevelTile(
            style: _styleFor(level, l),
            selected: level == selected,
            onTap: enabled ? () => onSelected(level) : null,
          ),
      ],
    );
  }

  static _LevelStyle _styleFor(EnhancementLevel level, AppLocalizations l) =>
      switch (level) {
        EnhancementLevel.lite => _LevelStyle(
            label: l.lite,
            description: l.liteLevelDescription,
            icon: Icons.spellcheck_rounded,
            color: AppColors.success,
          ),
        EnhancementLevel.medium => _LevelStyle(
            label: l.medium,
            description: l.mediumLevelDescription,
            icon: Icons.auto_fix_normal_rounded,
            color: AppColors.primary,
          ),
        EnhancementLevel.max => _LevelStyle(
            label: l.maximum,
            description: l.maxLevelDescription,
            icon: Icons.rocket_launch_rounded,
            color: AppColors.violet,
          ),
      };
}

/// Presentation d'un niveau (libelle localise, icone, couleur d'accent).
class _LevelStyle {
  const _LevelStyle({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final _LevelStyle style;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? style.color
                : colorScheme.outline.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          color: selected ? style.color.withValues(alpha: 0.05) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(style.icon, color: style.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected ? style.color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: style.color, size: 20),
          ],
        ),
      ),
    );
  }
}
