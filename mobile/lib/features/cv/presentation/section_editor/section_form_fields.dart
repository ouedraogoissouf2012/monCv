import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Champs de formulaire reutilisables des sections CV (issue #239).
///
/// Deplacees depuis `screens/cv/sections/form_sheet.dart` vers la couche
/// `features/cv/presentation` (sens de la migration Clean Architecture,
/// EPIC #231). Complementaire de `section_primitives.dart` : ici les widgets
/// de saisie (date, bouton IA, switch « poste actuel »), la ce sont ceux
/// d'affichage de liste (tuile, etat vide, bouton d'ajout).

// ── SectionDateButton ─────────────────────────────────────────

/// Bouton de selection de date (mois/annee), etat visuel selon presence.
class SectionDateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const SectionDateButton(
      {super.key, required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16,
                color: hasDate
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5))),
                Text(
                  hasDate
                      ? DateFormat('MMM yyyy',
                              Localizations.localeOf(context).toString())
                          .format(date!)
                      : AppLocalizations.of(context)!.choose,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasDate
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── AiSuggestButton ───────────────────────────────────────────

/// Bouton « suggestions IA » avec etat de chargement.
class AiSuggestButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const AiSuggestButton(
      {super.key, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: Text(isLoading
            ? AppLocalizations.of(context)!.generating
            : AppLocalizations.of(context)!.aiSuggestions),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
    );
  }
}

// ── SectionCurrentSwitch ──────────────────────────────────────

/// Switch « poste actuel / en cours » (masque la date de fin quand actif).
class SectionCurrentSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const SectionCurrentSwitch(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.work_history_outlined,
              size: 18,
              color: value
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.currentRole,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: value
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
