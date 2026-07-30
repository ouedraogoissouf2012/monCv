import 'package:flutter/material.dart';

import '../../../../../core/reference_data/country/country_catalog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../personal_info_form_controller.dart';
import 'city_autocomplete.dart';
import 'country_autocomplete.dart';

/// Groupe de champs « Localisation » : pays, ville, adresse, code postal
/// (issue #242).
///
/// Assemble [CountryAutocomplete] et [CityAutocomplete] (D3, fondes sur le
/// catalogue) et applique la regle metier « prefixer le telephone par
/// l'indicatif du pays choisi » extraite du monolithe (ex-`_onCountryChanged`).
class LocationFields extends StatelessWidget {
  const LocationFields({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onCountrySelected,
  });

  final PersonalInfoFormController controller;
  final VoidCallback onChanged;

  /// Notifie le parent qu'un pays a ete choisi (pour rafraichir l'affichage :
  /// helper telephone, suggestions de ville).
  final VoidCallback onCountrySelected;

  /// Applique l'indicatif du pays au telephone : si vide -> prefixe seul ;
  /// si commence par 0 -> remplace le 0 par l'indicatif. Sinon inchange.
  void _applyDialCode(String country) {
    final code = CountryCatalog.dialCodeFor(country);
    if (code == null) return;
    final tel = controller.telephone.text.trim();
    if (tel.isEmpty) {
      controller.telephone.text = '$code ';
    } else if (tel.startsWith('0')) {
      controller.telephone.text = '$code ${tel.substring(1)}';
    } else {
      return;
    }
    controller.telephone.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.telephone.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CountryAutocomplete(
          controller: controller.pays,
          onChanged: (country) {
            _applyDialCode(country);
            onCountrySelected();
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        CityAutocomplete(
          controller: controller.ville,
          country: controller.pays.text,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.adresse,
          decoration: InputDecoration(
            labelText: l.address,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            helperText: l.postalAddressHelper,
            hintText: l.addressExample,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.codePostal,
          decoration: InputDecoration(
            labelText: l.postalCode,
            helperText: l.optional,
            hintText: l.postalCodeExample,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
