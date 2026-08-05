import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../domain/password_policy.dart';
import 'auth_palette.dart';

/// Indicateur de force du mot de passe (issue #248, C4).
///
/// Mappe le niveau NEUTRE [PasswordStrength] (domaine, C1) vers une couleur du
/// design system et un libelle localise — la logique de couleur/label qui etait
/// melangee au calcul dans le monolithe (`Colors.red/orange` bruts) vit ici.
class AuthPasswordStrengthBar extends StatelessWidget {
  const AuthPasswordStrengthBar({
    super.key,
    required this.strength,
    required this.score,
  });

  final PasswordStrength strength;
  final double score;

  Color _color() => switch (strength) {
        PasswordStrength.weak => AppColors.error,
        PasswordStrength.medium => AppColors.warning,
        PasswordStrength.good => AppColors.primary,
        PasswordStrength.strong => AppColors.success,
      };

  String _label(AppLocalizations l) => switch (strength) {
        PasswordStrength.weak => l.passwordStrengthWeak,
        PasswordStrength.medium => l.passwordStrengthMedium,
        PasswordStrength.good => l.passwordStrengthGood,
        PasswordStrength.strong => l.passwordStrengthStrong,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _color();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 4,
              backgroundColor: AuthPalette.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(_label(l),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
