import 'package:flutter/material.dart';

/// Helpers d'accessibilite pour les widgets interactifs.

/// Wrap un widget avec des Semantics pour les lecteurs d'ecran.
Widget semanticButton({
  required Widget child,
  required String label,
  VoidCallback? onTap,
}) {
  return Semantics(
    button: true,
    label: label,
    child: child,
  );
}

/// Wrap une image avec une description pour les lecteurs d'ecran.
Widget semanticImage({
  required Widget child,
  required String description,
}) {
  return Semantics(
    image: true,
    label: description,
    child: child,
  );
}

/// Wrap un champ texte avec un label pour les lecteurs d'ecran.
Widget semanticTextField({
  required Widget child,
  required String label,
}) {
  return Semantics(
    textField: true,
    label: label,
    child: child,
  );
}

/// Constantes de contraste WCAG AA.
class AppContrast {
  /// Ratio minimum pour texte normal (4.5:1)
  static const double normalText = 4.5;

  /// Ratio minimum pour grand texte (3:1)
  static const double largeText = 3.0;

  /// Verifie si deux couleurs ont un contraste suffisant.
  static bool hasSufficientContrast(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = _contrastRatio(foreground, background);
    return ratio >= (isLargeText ? largeText : normalText);
  }

  static double _contrastRatio(Color c1, Color c2) {
    final l1 = _relativeLuminance(c1);
    final l2 = _relativeLuminance(c2);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color c) {
    double r = _linearize(c.r / 255.0);
    double g = _linearize(c.g / 255.0);
    double b = _linearize(c.b / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double v) {
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055).clamp(0, 1);
  }
}
