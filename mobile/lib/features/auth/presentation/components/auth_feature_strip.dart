import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'auth_palette.dart';

/// Bandeau de benefices (3 puces) sous la carte d'auth (issue #248, C2).
/// Mutualise `_buildFeatures` + `_FeatureChip`, dupliques dans login/register.
class AuthFeatureStrip extends StatelessWidget {
  const AuthFeatureStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AuthPalette.border, width: 0.5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: [
          AuthFeatureChip(l.featureAi),
          AuthFeatureChip(l.featurePdf),
          AuthFeatureChip(l.featureShare),
        ],
      ),
    );
  }
}

/// Puce d'un benefice : point bleu + libelle. Extraite a l'identique de
/// `_FeatureChip` (login:415-437 / register:526-548).
class AuthFeatureChip extends StatelessWidget {
  const AuthFeatureChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AuthPalette.blue.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(fontSize: 11, color: AuthPalette.muted)),
      ],
    );
  }
}
