import 'package:flutter/material.dart';

/// Ouvre une feuille modale **cadree** : le contenu est borne par un
/// [DraggableScrollableSheet] et son [ScrollController] est fourni au
/// constructeur de la feuille.
///
/// Evite le probleme d'affichage web ou une `showModalBottomSheet`
/// non contrainte s'ouvre trop bas et se retrouve coupee hors de l'ecran.
/// Transmettre le controller au `SingleChildScrollView` interne de la feuille
/// permet au drag de piloter le defilement (pas de conflit de scroll).
Future<T?> showDraggableBottomSheet<T>(
  BuildContext context,
  Widget Function(ScrollController) build, {
  double initialChildSize = 0.85,
  double minChildSize = 0.5,
  double maxChildSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (ctx, sc) => build(sc),
    ),
  );
}
