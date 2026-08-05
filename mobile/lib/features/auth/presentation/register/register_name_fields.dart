import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../components/auth_form_field.dart';

/// Champs Prenom + Nom de l'inscription (issue #248, C4). Row en large,
/// Column empilee en etroit. Extrait de `_buildNameFields`.
class RegisterNameFields extends StatelessWidget {
  const RegisterNameFields({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.narrow,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    AuthFormField field(String label, TextEditingController ctrl) =>
        AuthFormField(
          label: label,
          icon: Icons.person_outline,
          controller: ctrl,
          hint: label,
          compact: narrow,
          uppercaseLabel: false,
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
        );
    final first = field(l.firstName, firstName);
    final last = field(l.lastName, lastName);
    if (narrow) {
      return Column(children: [first, const SizedBox(height: 14), last]);
    }
    return Row(children: [
      Expanded(child: first),
      const SizedBox(width: 12),
      Expanded(child: last),
    ]);
  }
}
