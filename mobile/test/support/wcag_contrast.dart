import 'dart:math' as math;
import 'dart:ui';

/// Utilitaires de contraste WCAG 2.x, partages par les tests d'accessibilite.
///
/// Extraits de `test/utils/app_theme_contrast_test.dart` pour eviter la
/// duplication du calcul de luminance / ratio entre suites (design system,
/// themes). Les formules suivent la definition WCAG (luminance relative,
/// ratio `(L1 + 0.05) / (L2 + 0.05)`).

/// Ratio de contraste entre deux couleurs, dans l'ordre `[1, 21]`.
double contrastRatio(Color first, Color second) {
  final l1 = relativeLuminance(first);
  final l2 = relativeLuminance(second);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Luminance relative WCAG d'une couleur (composante alpha ignoree).
double relativeLuminance(Color color) {
  final argb = color.toARGB32();
  final red = (argb >> 16) & 0xff;
  final green = (argb >> 8) & 0xff;
  final blue = argb & 0xff;

  double channel(int value) {
    final normalized = value / 255;
    return normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(red) +
      0.7152 * channel(green) +
      0.0722 * channel(blue);
}

/// Seuil WCAG AA pour le texte normal.
const double kWcagAaNormalText = 4.5;

/// Seuil WCAG AA pour le texte large et les composants graphiques.
const double kWcagAaLargeText = 3.0;
