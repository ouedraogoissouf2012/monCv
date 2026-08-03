import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Poignee de la feuille modale d'amelioration IA (issue #244).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Titre + sous-titre du sheet selon le mode (amelioration ou relecture).
class EnhancementHeader extends StatelessWidget {
  const EnhancementHeader({super.key, required this.proofreadOnly});

  final bool proofreadOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                proofreadOnly
                    ? Icons.spellcheck_rounded
                    : Icons.auto_awesome_rounded,
                color: proofreadOnly ? AppColors.success : AppColors.violet,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              proofreadOnly ? l.proofreadingTitle : l.enhanceWithAi,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          proofreadOnly ? l.proofreadingSubtitle : l.enhancementSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}

/// Encart d'erreur affichant un message deja localise (issue #244).
class EnhancementErrorBanner extends StatelessWidget {
  const EnhancementErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: colorScheme.onErrorContainer, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
