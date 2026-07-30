import 'package:flutter/material.dart';

import '../../../../../core/reference_data/country/country_catalog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../personal_info_form_controller.dart';

/// Groupe de champs « Coordonnees » : email (valide) et telephone (issue #242).
///
/// Le helper du telephone affiche l'indicatif du pays courant via
/// [CountryCatalog] (source unique, D1) au lieu de l'ancienne table dupliquee.
class ContactFields extends StatelessWidget {
  const ContactFields({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final PersonalInfoFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pays = controller.pays.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.email,
          decoration: InputDecoration(
            labelText: '${l.emailShort} *',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            helperText: l.professionalEmailHelper,
            hintText: l.emailExample,
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => onChanged(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.emailMissing;
            if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
                .hasMatch(v.trim())) {
              return l.invalidEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.telephone,
          decoration: InputDecoration(
            labelText: l.phone,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            helperText: pays.isNotEmpty
                ? l.countryDialCodeAdded(
                    CountryCatalog.dialCodeFor(pays) ?? 'auto')
                : l.phoneCountryHelper,
            hintText: l.phoneExample,
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
