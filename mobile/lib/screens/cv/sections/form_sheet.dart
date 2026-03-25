import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── showFormSheet ─────────────────────────────────────────────

void showFormSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget Function(BuildContext, StateSetter) builder,
  required VoidCallback onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      final theme = Theme.of(ctx);

      return StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.15)),
                // Contenu
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: builder(ctx, setState),
                ),
                // Boutons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            onSave();
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Enregistrer',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ── SectionEmptyState ─────────────────────────────────────────

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
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          // Barre accent gauche
          Container(
            width: 4,
            height: 62,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
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

// ── SectionDateButton ─────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      ? DateFormat('MMM yyyy', 'fr_FR').format(date!)
                      : 'Choisir',
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

// ── SectionCurrentSwitch ──────────────────────────────────────

class SectionCurrentSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const SectionCurrentSwitch(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            child: Text('Poste actuel',
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
