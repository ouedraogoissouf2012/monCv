import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Wrapper qui centre et limite la largeur du contenu sur les grands écrans.
/// Sur mobile : affiche [child] sans contrainte.
/// Sur desktop/web : encadre dans une boîte max 480px centrée (pour les formulaires).
class CenteredFormLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredFormLayout({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Layout deux colonnes pour les grands écrans.
/// [sidebar] occupe [sidebarWidth], [body] prend le reste.
class TwoColumnLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget body;
  final double sidebarWidth;

  const TwoColumnLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.sidebarWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: sidebarWidth, child: sidebar),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ],
    );
  }
}
