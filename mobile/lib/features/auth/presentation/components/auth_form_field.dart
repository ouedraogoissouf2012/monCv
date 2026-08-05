import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import 'auth_palette.dart';

/// Champ de formulaire unifie des ecrans d'auth (issue #248, C2).
///
/// Fusionne les deux `_buildField` divergents de login et register :
/// - [uppercaseLabel] : login mettait le label en MAJUSCULES (letterSpacing) ;
///   register gardait la casse. Configurable ici.
/// - [onChanged], [compact] : options de register (force du mot de passe,
///   densite responsive) integrees.
/// Couleurs issues du design system (bordure d'erreur = AppColors.error, plus
/// de `Colors.red` brut).
class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.uppercaseLabel = true,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final bool uppercaseLabel;
  final bool compact;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uppercaseLabel ? label.toUpperCase() : label,
          style: TextStyle(
            fontSize: uppercaseLabel ? 11 : 12,
            fontWeight: FontWeight.w500,
            letterSpacing: uppercaseLabel ? 0.8 : 0,
            color: AuthPalette.muted,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          maxLines: 1,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14, color: AuthPalette.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.neutral250),
            prefixIcon: Icon(icon, size: 18, color: AuthPalette.muted),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8), child: suffixIcon)
                : null,
            suffixIconConstraints: const BoxConstraints(maxHeight: 24),
            filled: true,
            fillColor: AuthPalette.fieldBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: pad),
            border: _border(AuthPalette.border, 0.5),
            enabledBorder: _border(AuthPalette.border, 0.5),
            focusedBorder: _border(AuthPalette.blue, 1),
            errorBorder: _border(AppColors.error, 0.5),
          ),
        ),
      ],
    );
  }
}
