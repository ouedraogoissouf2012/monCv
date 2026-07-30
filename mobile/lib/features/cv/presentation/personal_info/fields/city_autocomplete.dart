import 'package:flutter/material.dart';

import '../../../../../data/city_suggestions.dart';
import '../../../../../l10n/app_localizations.dart';

/// Champ d'autocompletion de la ville, dependant du pays selectionne
/// (issue #242).
///
/// Extrait de l'ancien `_VilleAutocomplete`. Les suggestions proviennent de
/// `citySuggestionsByCountry` ; en l'absence de pays ou de suggestions, la
/// saisie reste libre.
class CityAutocomplete extends StatelessWidget {
  const CityAutocomplete({
    super.key,
    required this.controller,
    required this.country,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String country;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSuggestions = hasCitySuggestionsForCountry(country);
    final l = AppLocalizations.of(context)!;

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) => findCitySuggestions(
        country: country,
        query: textEditingValue.text,
      ),
      onSelected: (selection) {
        controller.text = selection;
        onChanged(selection);
      },
      fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
        if (ctrl.text != controller.text) {
          ctrl.value = TextEditingValue(
            text: controller.text,
            selection:
                TextSelection.collapsed(offset: controller.text.length),
          );
        }
        return TextFormField(
          key: const Key('city-field'),
          controller: ctrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l.city,
            prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
            helperText: hasSuggestions
                ? l.citySuggestionsForCountry(country)
                : country.trim().isEmpty
                    ? l.selectCountryForCities
                    : l.freeCityEntry,
            hintText: l.cityExample,
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            controller.text = value;
            onChanged(value);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.location_city_outlined, size: 16),
                  title: Text(option, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
