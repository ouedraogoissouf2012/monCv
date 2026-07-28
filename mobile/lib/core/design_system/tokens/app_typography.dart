import 'package:flutter/material.dart';

/// Catalogue typographique de l'application, source unique.
///
/// **Changer la police par defaut de l'app = changer [fontFamilyBody]** (et
/// [fontFamilyDisplay] pour les titres de marque). Ces deux constantes sont les
/// seules valeurs source; aucun ecran ne nomme une famille en dur ni n'appelle
/// `GoogleFonts` (issue #233). Les familles sont embarquees via `pubspec.yaml`,
/// donc resolues de facon deterministe, hors ligne et testables en golden.
abstract final class AppTypography {
  const AppTypography._();

  /// Famille du corps de texte et de l'interface. **Seule valeur a changer**
  /// pour re-typer toute l'application. Doit correspondre a une `family`
  /// declaree dans `pubspec.yaml > flutter > fonts`.
  static const String fontFamilyBody = 'Poppins';

  /// Famille des titres de marque (heros, logotype "MonCV"). Police a
  /// empattements, embarquee en variante variable.
  static const String fontFamilyDisplay = 'Playfair Display';

  /// Applique la famille de corps embarquee a un [TextTheme] de base, sans
  /// modifier l'echelle de tailles Material.
  ///
  /// Equivalent deterministe de `GoogleFonts.poppinsTextTheme(base)` : on
  /// conserve exactement la geometrie Material (tailles, graisses, interlignes
  /// des roles) et on ne change que la police. Aucune echelle custom n'est
  /// imposee ici, pour ne pas modifier le rendu du texte existant (contrainte
  /// de non-regression de l'issue #233).
  ///
  /// [base] doit etre le [TextTheme] par defaut du mode (clair ou sombre),
  /// afin que les couleurs par defaut restent coherentes avec la luminosite.
  static TextTheme textTheme([TextTheme? base]) {
    final source = base ?? const TextTheme();
    return source.apply(fontFamily: fontFamilyBody);
  }

  /// Style de titre de marque avec la police display embarquee
  /// ([fontFamilyDisplay]). Remplace les appels directs a `GoogleFonts` dans
  /// les ecrans (logotype "MonCV", titres de heros) : la police est resolue
  /// de facon deterministe, hors ligne, sans dependance reseau au runtime.
  ///
  /// Les tailles/poids sont fournis par l'appelant a l'identique de l'ancien
  /// `GoogleFonts.playfairDisplay(...)`, donc sans changement de rendu.
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
