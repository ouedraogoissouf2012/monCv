import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Bandeau hors-ligne de la liste des CV (issue #249, D4).
class CvListOfflineBanner extends StatelessWidget {
  const CvListOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.warning,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(AppLocalizations.of(context)!.offlineBanner,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

/// Etat vide de la liste des CV (issue #249, D4).
class CvListEmptyState extends StatelessWidget {
  const CvListEmptyState({super.key});

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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.description_outlined,
                  size: 50, color: colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(l.noCvYet,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l.createFirstCv,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/cvs/create'),
              icon: const Icon(Icons.add),
              label: Text(l.createMyFirstCv),
            ),
          ],
        ),
      ),
    );
  }
}
