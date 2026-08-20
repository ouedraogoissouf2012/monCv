import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/strict_date_input.dart';
import '../personal_info_form_controller.dart';

class SensitiveIdentityFields extends StatelessWidget {
  const SensitiveIdentityFields({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final PersonalInfoFormController controller;
  final VoidCallback onChanged;

  static const _situations = [
    'Celibataire',
    'Marie(e)',
    'Concubinage',
    'Divorce(e)',
    'Veuf(ve)',
  ];

  static const _sexes = ['Homme', 'Femme', 'Non precise'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.showSensitiveInfo),
          subtitle: Text(l.showSensitiveInfoHelp),
          value: controller.afficherInfosSensibles,
          onChanged: (value) {
            controller.afficherInfosSensibles = value;
            onChanged();
          },
        ),
        TextFormField(
          controller: controller.anneeNaissance,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: l.birthYear,
            helperText: l.birthYearHelp,
          ),
          onChanged: (_) => onChanged(),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final year = int.tryParse(value);
            const min = StrictDateInput.minYearDefault;
            final max = StrictDateInput.maxBirthYear();
            if (year == null || year < min || year > max) {
              return l.birthYearRange(min, max);
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _situations.contains(controller.situationMatrimoniale)
              ? controller.situationMatrimoniale
              : null,
          decoration: InputDecoration(labelText: l.maritalStatus),
          items: _situations
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            controller.situationMatrimoniale = value;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue:
              _sexes.contains(controller.sexe) ? controller.sexe : null,
          decoration: InputDecoration(labelText: l.sex),
          items: _sexes
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            controller.sexe = value;
            onChanged();
          },
        ),
      ],
    );
  }
}
