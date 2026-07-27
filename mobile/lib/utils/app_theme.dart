// mobile/lib/utils/app_theme.dart
import 'package:flutter/material.dart';

import '../core/design_system/theme/app_theme_factory.dart';
import '../core/design_system/theme/app_theme_mode.dart';
import '../core/design_system/theme/app_theme_modes.dart';

/// Facade de compatibilite vers le design system centralise (issue #233).
///
/// La definition des themes vit desormais dans `core/design_system/` : les
/// tokens (`tokens/`) et la fabrique commune (`theme/app_theme_factory.dart`).
/// Cette classe ne fait que router `mode -> ThemeData/ColorScheme` pour les
/// appelants existants (`main.dart`, tests) sans changer leur API.
///
/// Nouveau code : preferer `AppThemeFactory.build(AppThemeModes.of(mode))` et
/// les tokens directement. Cette facade sera retiree une fois tous les
/// appelants migres (suivi de #233).
class AppThemes {
  const AppThemes._();

  /// [ColorScheme] du mode demande.
  static ColorScheme colorScheme(AppThemeMode mode) =>
      AppThemeModes.of(mode).colorScheme;

  /// [ThemeData] complet du mode demande, produit par la fabrique commune.
  static ThemeData get(AppThemeMode mode) =>
      AppThemeFactory.build(AppThemeModes.of(mode));
}
