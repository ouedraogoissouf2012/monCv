import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/result.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../repositories/cv_trash_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../cv/presentation/controllers/cv_editor_controller.dart';
import '../../cv/presentation/controllers/cv_list_controller.dart' as cvp;
import '../../cv/presentation/cv_store.dart';
import '../../../services/pdf_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive.dart';
import '../../../screens/share/share_portfolio_dialog.dart';
import '../application/import_cv.dart';
import 'components/cv_card.dart';
import 'components/cv_list_actions.dart';
import 'components/cv_list_states.dart';
import 'components/cv_list_view.dart';
import 'cv_list_controller.dart';
import 'cv_trash_screen.dart';

/// Liste des CV de l'utilisateur (issue #249, D4).
///
/// Orchestrateur mince : navigation via [AppShell] (D2), cartes via [CvCard]
/// (D3), actions (import/suppression/duplication) deleguees a
/// [CvListController]. Remplace `home_screen.dart` (350 l.).
class CvListScreen extends StatefulWidget {
  const CvListScreen({super.key, required this.importCv});

  /// Use case d'import injecte au routeur (composition root, issue #249 D4).
  final ImportCvUseCase importCv;

  @override
  State<CvListScreen> createState() => _CvListScreenState();
}

class _CvListScreenState extends State<CvListScreen> {
  late final CvListController _controller;

  @override
  void initState() {
    super.initState();
    final listController = context.read<cvp.CvListController>();
    final editor = context.read<CvEditorController>();
    _controller = CvListController(
      importCv: widget.importCv,
      pickFile: _pickFile,
      reload: () => listController.load().then((_) => true),
      deleteCv: editor.delete,
      duplicateCv: editor.duplicate,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => listController.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<CvImportFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    final file = (result == null || result.files.isEmpty)
        ? null
        : result.files.first;
    if (file?.bytes == null) return null;
    return CvImportFile(filename: file!.name, bytes: file.bytes!);
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    final outcome = await _controller.importFromFile();
    if (!mounted || outcome == null) return;
    final ok = outcome == CvListActionOutcome.success;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? l.importSuccess(_controller.importedTitle ?? '')
          : importErrorMessage(l, _controller.importError)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.success : null,
    ));
  }

  Future<void> _downloadPdf(Cv cv) => _download(
      () => context.read<PdfService>().downloadPdf(cv),
      _l.pdfDownloaded, _l.pdfError);

  Future<void> _downloadDocx(int id) => _download(
      () => context.read<PdfService>().downloadDocx(id),
      _l.docxDownloaded, _l.docxError);

  Future<void> _download(Future<void> Function() run, String okMessage,
      String Function(String) errorMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(okMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(errorMessage('')),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _confirmAction(
      Future<bool> Function() action, String okMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<CvStore>();
    final l = AppLocalizations.of(context)!;
    final ok = await action();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? okMessage : store.state.errorMessage ?? l.errorGeneric),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.success : Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _delete(int id, String titre) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCvTitle),
        content: Text(l.deleteCvConfirm(titre)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              child: Text(l.delete)),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final list = context.read<cvp.CvListController>();
    final ok = await _controller.deleteCv(id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? l.cvMovedToTrash : l.errorGeneric),
      behavior: SnackBarBehavior.floating,
      action: ok
          ? SnackBarAction(
              label: l.undo,
              onPressed: () async {
                final restored = await sl<CvTrashRepository>().restore(id);
                if (restored is Success) await list.load();
              },
            )
          : null,
    ));
  }

  Future<void> _share(Cv cv) async {
    final changed = await showDialog<bool>(
        context: context, builder: (_) => SharePortfolioDialog(cv: cv));
    if (changed == true && mounted) await context.read<cvp.CvListController>().load();
  }

  AppLocalizations get _l => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDesktop = Responsive.isDesktop(context);
    return DefaultTabController(
      length: 2,
      child: AppShell(
      currentIndex: 0,
      title: l.myCvs,
      actions: [
        CvImportButton(controller: _controller, onImport: _import),
        if (isDesktop) const CvNewButton(),
      ],
      floatingActionButton: isDesktop ? null : const CvNewFab(),
      body: Column(
        children: [
          TabBar(tabs: [
            Tab(text: l.myCvs),
            Tab(text: l.trashTitle),
          ]),
          Expanded(
            child: TabBarView(children: [
              Consumer<CvStore>(
                builder: (context, store, _) {
                  if (store.state.isLoading && store.cvs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (store.cvs.isEmpty) return const CvListEmptyState();
                  return Column(
                    children: [
                      if (store.isOffline) const CvListOfflineBanner(),
                      Expanded(
                          child: CvListView(cvs: store.cvs, itemBuilder: _card)),
                    ],
                  );
                },
              ),
              const CvTrashScreen(embedded: true),
            ]),
          ),
        ],
      ),
      ),
    );
  }

  Widget _card(Cv cv) => CvCard(
        cv: cv,
        onTap: () => context.push('/cvs/${cv.id}'),
        onEdit: () => context.push('/cvs/${cv.id}/edit', extra: cv),
        onDownloadPdf: () => _downloadPdf(cv),
        onDownloadDocx: () => _downloadDocx(cv.id!),
        onDelete: () => _delete(cv.id!, cv.titre),
        onDuplicate: () => _confirmAction(
            () => _controller.duplicateCv(cv.id!), _l.cvDuplicated),
        onShare: () => _share(cv),
      );
}
