import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import 'auth_background.dart';
import 'auth_palette.dart';

/// Ossature commune des ecrans d'authentification (issue #248, C2).
///
/// Scaffold + grille de fond + orbes flottantes + contenu centre defilable.
/// Mutualise la structure dupliquee de login/register. Les orbes ont un jeu par
/// defaut (surchargeable) pour eviter la re-declaration dans chaque ecran.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.orbs});

  /// Contenu centre (typiquement une [AuthCard]).
  final Widget child;

  /// Orbes de fond ; par defaut le jeu a 3 orbes de login.
  final List<Widget>? orbs;

  static const List<Widget> _defaultOrbs = [
    AuthFloatingOrb(
        size: 500, color: AuthPalette.blue, opacity: 0.10, top: -100, right: -100, delay: 0),
    AuthFloatingOrb(
        size: 400, color: AuthPalette.blue, opacity: 0.06, bottom: -80, left: -80, delay: 3),
    AuthFloatingOrb(
        size: 300,
        color: AppColors.violetMuted,
        opacity: 0.07,
        top: 200,
        left: 150,
        delay: 6),
  ];

  /// Jeu a 2 orbes (variante register).
  static const List<Widget> twoOrbs = [
    AuthFloatingOrb(
        size: 500, color: AuthPalette.blue, opacity: 0.10, top: -100, right: -100, delay: 0),
    AuthFloatingOrb(
        size: 400, color: AuthPalette.blue, opacity: 0.06, bottom: -80, left: -80, delay: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: Stack(
        children: [
          const AuthGridBackground(),
          ...(orbs ?? _defaultOrbs),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte animee (fade + slide) qui porte le formulaire d'auth (issue #248, C2).
/// Extraite du `_buildCard` duplique.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(36, 40, 36, 32),
    this.borderRadius = 28,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460),
        padding: padding,
        decoration: BoxDecoration(
          color: AuthPalette.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AuthPalette.border, width: 0.5),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowMedium, blurRadius: 64, offset: Offset(0, 24)),
            BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}
