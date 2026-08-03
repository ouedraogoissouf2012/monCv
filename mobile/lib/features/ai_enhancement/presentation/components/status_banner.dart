import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Banniere de provenance du resultat IA (issue #244).
///
/// Indique si le contenu a ete genere par l'IA ([aiGenerated] vrai) ou produit
/// par le fallback deterministe. Extrait de l'entete de `_ResultSection`.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.aiGenerated});

  final bool aiGenerated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(
          aiGenerated
              ? Icons.auto_awesome_rounded
              : Icons.warning_amber_rounded,
          size: 16,
          color: aiGenerated ? AppColors.success : colorScheme.error,
        ),
        const SizedBox(width: 6),
        Text(
          aiGenerated ? l.enhancementGenerated : l.fallbackResult,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: aiGenerated ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }
}
