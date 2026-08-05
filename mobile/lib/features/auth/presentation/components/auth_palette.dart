import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';

/// Palette partagee des ecrans d'authentification (issue #248, C2).
///
/// Mutualise les 7 alias de couleurs qui etaient dupliques a l'identique en
/// tete de login_screen.dart et register_screen.dart. Toutes pointent vers le
/// design system (#233) — aucune couleur codee en dur.
abstract final class AuthPalette {
  static const Color blue = AppColors.brandBlue;
  static const Color background = AppColors.warmBackground;
  static const Color text = AppColors.neutral850;
  static const Color muted = AppColors.neutral400;
  static const Color border = AppColors.neutral200;
  static const Color white = AppColors.white;
  static const Color fieldBackground = AppColors.warmSurface;
}
