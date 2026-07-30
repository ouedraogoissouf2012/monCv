import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../personal_info_form_controller.dart';

/// Groupe de champs « Identite » : prenom, nom, titre de poste (issue #242).
///
/// Extrait du monolithe `personal_info_section.dart`. Prend le
/// [PersonalInfoFormController] (D2) et notifie le parent via [onChanged] a
/// chaque saisie ; ne construit jamais le modele lui-meme.
class IdentityFields extends StatelessWidget {
  const IdentityFields({
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.prenom,
                decoration: InputDecoration(
                  labelText: l.firstNameRequired,
                  helperText: l.firstNameExample,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => onChanged(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.firstNameMissing
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller.nom,
                decoration: InputDecoration(
                  labelText: l.lastNameRequired,
                  helperText: l.lastNameExample,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => onChanged(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.lastNameMissing
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.titrePoste,
          decoration: InputDecoration(
            labelText: l.jobTitle,
            helperText: l.targetJobHelper,
            hintText: l.jobTitleExample,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
