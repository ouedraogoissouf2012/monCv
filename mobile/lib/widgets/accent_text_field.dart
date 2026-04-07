import 'package:flutter/material.dart';
import '../services/accent_corrector.dart';

/// TextFormField qui corrige automatiquement les accents
/// quand l'utilisateur quitte le champ (perte de focus).
class AccentTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final bool enableAccentCorrection;

  const AccentTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.enableAccentCorrection = true,
  });

  @override
  State<AccentTextField> createState() => _AccentTextFieldState();
}

class _AccentTextFieldState extends State<AccentTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Corriger les accents quand l'utilisateur QUITTE le champ
    if (!_focusNode.hasFocus && widget.enableAccentCorrection) {
      final original = widget.controller.text;
      final corrected = AccentCorrector().correct(original);
      if (corrected != original) {
        widget.controller.text = corrected;
        // Placer le curseur a la fin
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: corrected.length),
        );
        widget.onChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onChanged: (_) => widget.onChanged?.call(),
    );
  }
}
