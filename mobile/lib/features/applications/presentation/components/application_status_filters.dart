import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/job_application_status.dart';
import 'application_status_presentation.dart';

/// Barre de filtres par statut (issue #246, A6a). `null` = tous.
/// Reutilise le mapping centralise pour les libelles.
class ApplicationStatusFilters extends StatelessWidget {
  const ApplicationStatusFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final JobApplicationStatus? selected;
  final ValueChanged<JobApplicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final values = <JobApplicationStatus?>[null, ...JobApplicationStatus.values];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          return ChoiceChip(
            label: Text(value == null
                ? l.all
                : ApplicationStatusPresentation.label(l, value)),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}
