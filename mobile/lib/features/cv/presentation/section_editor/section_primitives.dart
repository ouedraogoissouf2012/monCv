import 'package:flutter/material.dart';

/// Primitives visuelles reutilisables des sections CV (issue #239).
///
/// Deplacees depuis `screens/cv/sections/form_sheet.dart` vers la couche
/// `features/cv/presentation` pour que le neuf ne dependent plus du legacy
/// (sens de la migration Clean Architecture, EPIC #231). `form_sheet.dart`
/// les re-exporte le temps que les 6 sections legacy soient migrees (PR-C).

// ── SectionEmptyState ─────────────────────────────────────────

/// Etat vide d'une section (icone + libelle attenue).
class SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const SectionEmptyState({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                size: 28,
                color: colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SectionItemTile ───────────────────────────────────────────

/// Tuile d'item de section : titre, sous-titre, badge optionnel, actions
/// edit / delete. Disposition par defaut de [EditableSectionList].
class SectionItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SectionItemTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          // Barre accent gauche
          Container(
            width: 4,
            height: 62,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.55),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          // Contenu
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? Colors.green)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(badge!,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? Colors.green)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.primary.withValues(alpha: 0.8)),
                onPressed: onEdit,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: colorScheme.error.withValues(alpha: 0.8)),
                onPressed: onDelete,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── SectionAddButton ──────────────────────────────────────────

/// Bouton d'ajout d'item (bordure pointillee-like, teinte primaire).
class SectionAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SectionAddButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.primary.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
