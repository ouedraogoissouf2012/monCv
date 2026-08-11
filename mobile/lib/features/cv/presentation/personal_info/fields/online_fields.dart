import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../personal_info_form_controller.dart';

/// Groupe de champs « En ligne » : LinkedIn et portfolio (issue #242).
class OnlineFields extends StatelessWidget {
  const OnlineFields({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final PersonalInfoFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.linkedIn,
          decoration: InputDecoration(
            labelText: l.linkedin,
            prefixIcon: const Icon(Icons.link_rounded, size: 20),
            hintText: l.linkedinHint,
            helperText: l.linkedinHelper,
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.portfolio,
          decoration: InputDecoration(
            labelText: l.portfolio,
            prefixIcon: const Icon(Icons.language_rounded, size: 20),
            hintText: l.portfolioHint,
            helperText: l.portfolioHelper,
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
