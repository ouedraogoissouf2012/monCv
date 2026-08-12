import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../providers/cv_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/ai_enhance_sheet.dart';
import '../../../widgets/cv_preview.dart';
import '../../../widgets/draggable_bottom_sheet.dart';
import '../../../widgets/job_match_sheet.dart';
import '../../ai/domain/entities/enhanced_cv.dart';
import 'cv_detail_controller.dart';
import 'components/cv_detail_app_bar.dart';

/// Ecran de detail d'un CV (issue #247, B4b).
///
/// Orchestrateur mince : le chargement/enhancement passe par [CvProvider], les
/// exports par [CvDetailController] (B3, garde double-clic + erreurs typees).
/// Remplace le monolithe de 734 lignes. L'ancien bloc de creation de variante
/// (mort : JobMatchSheet ferme sans valeur) est SUPPRIME — la variante se cree
/// desormais dans JobMatchSheet (G3).
class CvDetailScreen extends StatefulWidget {
  const CvDetailScreen({super.key, required this.cvId, required this.controller});

  final int cvId;
  final CvDetailController controller;

  @override
  State<CvDetailScreen> createState() => _CvDetailScreenState();
}

class _CvDetailScreenState extends State<CvDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvById(widget.cvId);
    });
  }

  Future<void> _export(Future<ExportOutcome> Function() run) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    final outcome = await run();
    if (!mounted) return;
    final ok = outcome == ExportOutcome.success;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? l.pdfDownloaded : l.pdfError('')),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.success : null,
    ));
  }

  Future<void> _openEnhancement(Cv cv, {bool proofreadOnly = false}) async {
    final provider = context.read<CvProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    final result = await showDraggableBottomSheet<EnhancedCv>(
      context,
      (sc) => AiEnhanceSheet(
          cv: cv, proofreadOnly: proofreadOnly, scrollController: sc),
    );
    if (result == null || !mounted) return;
    final ok = await provider.applyEnhancedCv(cv.id!, result);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? (proofreadOnly ? l.spellingCorrectionsApplied : l.aiSuggestionsApplied)
          : l.applicationError),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.success : null,
    ));
  }

  /// Ouvre l'analyse d'offre. La creation de variante est geree DANS le sheet
  /// (G3, invariant une-fois) : plus de duplication + recherche "Copie de" ici.
  void _adaptToJob(Cv cv) => showDraggableBottomSheet<void>(
        context,
        (_) => JobMatchSheet(cvId: cv.id!),
      );

  CvDetailTooltips _tooltips(AppLocalizations l) => CvDetailTooltips(
        proofread: l.proofreadSpelling,
        enhance: l.enhanceWithAi,
        adaptToJob: l.adaptToJob,
        customize: l.customize,
        downloadPdf: l.downloadPdf,
        downloadDocx: l.downloadDocx,
        edit: l.edit,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<CvProvider>(
      builder: (context, cvProvider, _) {
        final cv = cvProvider.currentCv;
        if (cvProvider.isLoading || cv == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.myCv)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => Scaffold(
            appBar: CvDetailAppBar(
              title: cv.titre,
              exportingPdf: widget.controller.exportingPdf,
              exportingDocx: widget.controller.exportingDocx,
              tooltips: _tooltips(l),
              onBack: () => context.pop(),
              onProofread: () => _openEnhancement(cv, proofreadOnly: true),
              onEnhance: () => _openEnhancement(cv),
              onAdaptToJob: () => _adaptToJob(cv),
              onCustomize: () => context.push('/cvs/${cv.id}/style', extra: cv),
              onExportPdf: () => _export(() => widget.controller.exportPdf(cv)),
              onExportDocx: () =>
                  _export(() => widget.controller.exportDocx(cv.id!)),
              onEdit: () => context.push('/cvs/${cv.id}/edit', extra: cv),
            ),
            body: CvPreviewWidget(cv: cv),
          ),
        );
      },
    );
  }
}
