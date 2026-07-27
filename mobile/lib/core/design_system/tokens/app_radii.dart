import 'package:flutter/widgets.dart';

/// Rayons de bordure de l'application, source unique.
///
/// Valeurs alignees sur l'usage reel du code (mesures : 8, 10, 12, 16, 20
/// dominent; 999 sert de "pilule"). Expose les rayons scalaires ([smValue]...)
/// pour composer et les [BorderRadius] prets a l'emploi pour le cas courant.
abstract final class AppRadii {
  const AppRadii._();

  /// 4 dp — coins discrets (barres de progression fines, puces).
  static const double xsValue = 4;

  /// 8 dp — cartes compactes, champs denses.
  static const double smValue = 8;

  /// 10 dp — conteneurs d'icones, boutons secondaires.
  static const double mdValue = 10;

  /// 12 dp — rayon par defaut (boutons, champs de saisie).
  static const double lgValue = 12;

  /// 16 dp — cartes de contenu.
  static const double xlValue = 16;

  /// 20 dp — feuilles modales, grands conteneurs.
  static const double xxlValue = 20;

  /// Rayon "pilule" : garantit des extremites totalement arrondies quelle que
  /// soit la hauteur (badges, chips, boutons ronds).
  static const double pillValue = 999;

  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsValue));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(xxlValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));
}
