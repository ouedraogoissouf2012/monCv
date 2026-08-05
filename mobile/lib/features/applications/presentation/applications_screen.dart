import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/cv_provider.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../utils/responsive.dart';
import '../domain/external_link_launcher.dart';
import '../domain/job_application.dart';
import 'application_form/application_form_sheet.dart';
import 'application_list_controller.dart';
import 'components/applications_list_view.dart';

/// Dialogue de confirmation de suppression. Extrait pour garder l'ecran mince.
Future<bool?> _confirmDelete(BuildContext context, JobApplication value) {
  final l = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteApplication),
      content: Text(l.deleteApplicationConfirm(value.company)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
      ],
    ),
  );
}

/// Ecran des candidatures (issue #246, A6b).
///
/// Orchestrateur mince : la logique vit dans [ApplicationListController]
/// (injecte). Remplace le monolithe de 606 lignes. Ouverture d'URL via
/// [ExternalLinkLauncher] (validation A3).
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.controller, required this.linkLauncher});

  final ApplicationListController controller;
  final ExternalLinkLauncher linkLauncher;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  ApplicationListController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.load();
      context.read<CvProvider>().loadCvs();
    });
  }

  Future<void> _openForm([JobApplication? initial]) async {
    final result = await showModalBottomSheet<JobApplication>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ApplicationFormSheet(initial: initial),
    );
    if (result != null) await _c.save(result);
  }

  Future<void> _delete(JobApplication value) async {
    final ok = await _confirmDelete(context, value);
    if (ok == true && value.id != null) await _c.delete(value.id!);
  }

  Future<void> _openUrl(JobApplication value) async {
    final l = AppLocalizations.of(context)!;
    final result = await widget.linkLauncher.open(value.offerUrl);
    if (!mounted || result == LinkLaunchResult.success) return;
    final msg =
        result == LinkLaunchResult.invalidUrl ? l.invalidUrl : l.couldNotOpenLink;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDesktop = Responsive.isDesktop(context);
    return AppShell(
      currentIndex: 2,
      title: l.applications,
      actions: isDesktop
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.addApplication)),
              ),
            ]
          : null,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              tooltip: l.addApplication,
              onPressed: () => _openForm(),
              child: const Icon(Icons.add)),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final state = _c.state;
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ApplicationsListView(
            controller: _c,
            horizontalPadding: isDesktop ? 24 : 16,
            onAdd: () => _openForm(),
            onEdit: _openForm,
            onDelete: _delete,
            onOpenUrl: _openUrl,
          );
        },
      ),
    );
  }
}
