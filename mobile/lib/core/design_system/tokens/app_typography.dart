import 'package:flutter/material.dart';

/// Catalogue typographique de l'application, source unique.
///
/// **Changer la police par defaut de l'app = changer [fontFamilyBody]** (et
/// [fontFamilyDisplay] pour les titres de marque). Ces deux constantes sont les
/// seules valeurs source; aucun ecran ne nomme une famille en dur ni n'appelle
/// `GoogleFonts` (issue #233). Les familles sont embarquees via `pubspec.yaml`,
/// donc resolues de facon deterministe, hors ligne et testables en golden.
///
/// L'echelle reprend les roles Material 3 et s'aligne sur les tailles reellement
/// utilisees dans le code (corps 11-14 dp dominant, titres jusqu'a 52 dp).
abstract final class AppTypography {
  const AppTypography._();

  /// Famille du corps de texte et de l'interface. **Seule valeur a changer**
  /// pour re-typer toute l'application. Doit correspondre a une `family`
  /// declaree dans `pubspec.yaml > flutter > fonts`.
  static const String fontFamilyBody = 'Poppins';

  /// Famille des titres de marque (heros, logotype "MonCV"). Police a
  /// empattements, embarquee en variante variable.
  static const String fontFamilyDisplay = 'Playfair Display';

  /// Interlignage confortable par defaut pour le corps.
  static const double _bodyHeight = 1.4;

  /// Interlignage resserre pour les grands titres.
  static const double _displayHeight = 1.16;

  /// Construit le [TextTheme] de base de l'application a partir de la famille
  /// de corps. Les couleurs restent portees par le [ColorScheme]; on ne fixe
  /// ici que la geometrie (taille, graisse, interlignage), jamais la teinte.
  static TextTheme textTheme() => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          height: _displayHeight,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: _displayHeight,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: _bodyHeight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: _bodyHeight,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: _bodyHeight,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ).apply(fontFamily: fontFamilyBody);

  /// Style de titre de marque avec la police display embarquee
  /// ([fontFamilyDisplay]). Remplace les appels directs a `GoogleFonts` dans
  /// les ecrans (logotype "MonCV", titres de heros) : la police est resolue
  /// de facon deterministe, hors ligne, sans dependance reseau au runtime.
  static TextStyle display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamilyDisplay,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
