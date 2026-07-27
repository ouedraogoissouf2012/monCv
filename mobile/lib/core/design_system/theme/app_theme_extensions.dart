import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Acces ergonomique aux tokens du design system depuis un [BuildContext].
///
/// Evite la formule verbeuse `Theme.of(context).extension<AppColorTokens>()!`
/// dans les widgets. Le `!` est intentionnel : l'extension est toujours
/// enregistree par la factory de theme; son absence est un bug de cablage a
/// faire echouer tot, pas a masquer par un fallback silencieux.
extension AppThemeContextX on BuildContext {
  /// Couleurs semantiques metier du theme courant (success, warning, statuts...).
  AppColorTokens get colorTokens => Theme.of(this).extension<AppColorTokens>()!;

  /// Raccourci vers le [ColorScheme] Material du theme courant.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Raccourci vers le [TextTheme] du theme courant.
  TextTheme get textStyles => Theme.of(this).textTheme;
}
