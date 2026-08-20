import 'package:flutter/material.dart';

import '../../../../../core/reference_data/country/country_catalog.dart';
import '../../../../../l10n/app_localizations.dart';

/// Champ d'autocompletion du pays, fonde sur la source de verite unique
/// [CountryCatalog] (issue #242).
///
/// Remplace l'ancien `_PaysAutocomplete` qui embarquait sa propre liste de
/// pays dupliquee. La recherche est insensible casse/accents (via
/// `CountryCatalog.search` : prefixe uniquement, zone Afrique/Francophonie
/// prioritaire.
class CountryAutocomplete extends StatelessWidget {
  const CountryAutocomplete({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) => CountryCatalog
          .search(textEditingValue.text)
          .map((c) => c.nameFr),
      onSelected: (selection) {
        controller.text = selection;
        onChanged(selection);
      },
      fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
        ctrl.text = controller.text;
        return TextFormField(
          key: const Key('country-field'),
          controller: ctrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l.country,
            prefixIcon: const Icon(Icons.flag_outlined, size: 20),
            helperText: l.countryDialCodeHelper,
            hintText: l.countryExample,
          ),
          onChanged: (v) {
            controller.text = v;
            onChanged(v);
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
                  leading: const Icon(Icons.flag_outlined, size: 16),
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
