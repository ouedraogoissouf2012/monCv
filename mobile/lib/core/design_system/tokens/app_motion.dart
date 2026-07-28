import 'package:flutter/animation.dart';

/// Tokens de mouvement : durees et courbes d'animation, source unique.
///
/// Les durees refletent les micro-interactions reelles du code (150/200/300 ms)
/// et separent explicitement l'animation d'interface des delais fonctionnels
/// (timeouts reseau, affichage de snackbars) qui ne sont PAS du motion et
/// vivent ailleurs. Ici on ne place que ce qui anime des pixels.
abstract final class AppMotion {
  const AppMotion._();

  /// 150 ms — transitions instantanees percues (survol, pression).
  static const Duration fast = Duration(milliseconds: 150);

  /// 200 ms — transitions standard (apparition de contenu, bascules).
  static const Duration normal = Duration(milliseconds: 200);

  /// 300 ms — transitions amples (feuilles modales, expansions).
  static const Duration slow = Duration(milliseconds: 300);

  /// Courbe par defaut : deceleration naturelle pour l'entree d'elements.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Courbe symetrique pour les bascules d'etat (on/off).
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
}
