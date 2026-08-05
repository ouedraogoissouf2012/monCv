import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Etat vide de la liste des candidatures (issue #246, A6a).
class ApplicationsEmptyState extends StatelessWidget {
  const ApplicationsEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(l.noApplications,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l.noApplicationsDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l.addApplication),
            ),
          ],
        ),
      ),
    );
  }
}
