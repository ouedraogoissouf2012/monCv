import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Encart de consentement au traitement IA des donnees (issue #244).
///
/// Extrait de `_AiConsentNotice`. Primitive reutilisable (le meme consentement
/// vaut pour enhance / job match / messages, cf. critere #244) : ne porte
/// aucune logique metier, seulement l'affichage et le rappel de l'etat.
class ConsentNotice extends StatelessWidget {
  const ConsentNotice({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l.aiConsent,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
