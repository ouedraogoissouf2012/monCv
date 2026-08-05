import 'package:flutter/material.dart';

import '../../domain/job_application.dart';
import '../application_list_controller.dart';
import 'application_list_row.dart';
import 'applications_empty_state.dart';
import 'application_status_filters.dart';
import 'follow_up_banner.dart';

/// Corps de l'ecran des candidatures (issue #246, A6b) : banniere de relances,
/// filtres, erreur, et liste (ou etat vide). Pilote par le controller ; toutes
/// les actions remontent via callbacks pour garder l'ecran mince.
class ApplicationsListView extends StatelessWidget {
  const ApplicationsListView({
    super.key,
    required this.controller,
    required this.horizontalPadding,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenUrl,
  });

  final ApplicationListController controller;
  final double horizontalPadding;
  final VoidCallback onAdd;
  final ValueChanged<JobApplication> onEdit;
  final ValueChanged<JobApplication> onDelete;
  final ValueChanged<JobApplication> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final due = controller.dueItems;
    return RefreshIndicator(
      onRefresh: () => controller.load(status: state.filter),
      child: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 96),
        children: [
          if (due.isNotEmpty) ...[
            FollowUpBanner(count: due.length),
            const SizedBox(height: 12),
          ],
          ApplicationStatusFilters(
              selected: state.filter,
              onSelected: (s) => controller.load(status: s)),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          if (state.items.isEmpty)
            ApplicationsEmptyState(onAdd: onAdd)
          else
            ...state.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApplicationListRow(
                    value: item,
                    isDue: due.contains(item),
                    onEdit: () => onEdit(item),
                    onDelete: () => onDelete(item),
                    onOpenUrl: () => onOpenUrl(item),
                  ),
                )),
        ],
      ),
    );
  }
}
