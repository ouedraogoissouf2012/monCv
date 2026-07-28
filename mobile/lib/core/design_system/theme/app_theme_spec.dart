import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Description declarative de **ce qui differe** entre les themes de l'app
/// (Minimal, Vibrant, Premium). Tout ce qui est commun — rayons, paddings,
/// formes de boutons, densites — vit dans `AppThemeFactory`, jamais ici.
///
/// Un mode = une instance de [AppThemeSpec]. Ajouter un theme = ajouter une
/// fabrique statique, sans dupliquer un seul theme de composant (issue #233).
@immutable
class AppThemeSpec {
  const AppThemeSpec({
    required this.colorScheme,
    required this.brightness,
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.cardColor,
    required this.inputFill,
    required this.colorTokens,
    this.cardShadowColor,
    this.cardBorderColor,
    this.inputEnabledBorderColor,
    this.flattenAppBarTint = false,
  });

  /// Roles de couleur Material du mode.
  final ColorScheme colorScheme;

  /// Clair ou sombre : pilote les valeurs par defaut de Material.
  final Brightness brightness;

  /// Fond de l'ecran (scaffold).
  final Color scaffoldBackground;

  /// Fond de la barre d'application.
  final Color appBarBackground;

  /// Premier plan (titre, icones) de la barre d'application.
  final Color appBarForeground;

  /// Fond des cartes.
  final Color cardColor;

  /// Couleur d'ombre des cartes lorsqu'elles ont une elevation > 0. `null`
  /// laisse le defaut Material. Seul Minimal la fixait (`Colors.black12`) dans
  /// le theme d'origine : on reproduit cet etat (non-regression #233).
  final Color? cardShadowColor;

  /// Remplissage des champs de saisie.
  final Color inputFill;

  /// Couleurs semantiques metier associees a ce mode.
  final AppColorTokens colorTokens;

  /// Ligne de contour optionnelle des cartes (Premium l'utilise; sinon `null`
  /// = pas de bordure).
  final Color? cardBorderColor;

  /// Contour optionnel des champs au repos (Premium l'utilise; sinon `null`
  /// = champ sans bordure au repos).
  final Color? inputEnabledBorderColor;

  /// Neutralise la teinte de surface Material sur la barre d'application
  /// (`surfaceTintColor: transparent`). `false` conserve le comportement M3
  /// par defaut. Seul le mode Vibrant l'activait dans le theme d'origine :
  /// on reproduit cet etat exact (non-regression #233).
  final bool flattenAppBarTint;
}
