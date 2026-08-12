import 'package:flutter/material.dart';

import '../../../core/error/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../cv_export/application/export_cv_pdf.dart';
import 'components/cv_style_draggable_divider.dart';
import 'components/cv_style_options_pane.dart';
import 'components/cv_style_preview_pane.dart';
import 'cv_style_controller.dart';

/// Ecran d'edition du style d'un CV (issue #247, B4a).
///
/// Route GoRouter dediee (remplace la MaterialPageRoute imbriquee du monolithe,
/// crit. #247). L'autosave (debounce/retry/rollback) vit dans
/// [CvStyleController] (B2) ; l'export PDF passe par [ExportCvPdfUseCase] (B1).
class CvStyleEditorScreen extends StatefulWidget {
  const CvStyleEditorScreen({
    super.key,
    required this.cv,
    required this.controller,
    required this.exportPdf,
  });

  final Cv cv;
  final CvStyleController controller;
  final ExportCvPdfUseCase exportPdf;

  static const double _wideBreakpoint = 900;

  @override
  State<CvStyleEditorScreen> createState() => _CvStyleEditorScreenState();
}

class _CvStyleEditorScreenState extends State<CvStyleEditorScreen> {
  bool _showPreview = false;
  bool _downloading = false;
  double _optionsWidth = 320;

  CvStyleController get _c => widget.controller;

  Cv get _styledCv => widget.cv.copyWith(style: _c.style);

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    final result = await widget.exportPdf(_styledCv);
    if (!mounted) return;
    setState(() => _downloading = false);
    messenger.showSnackBar(SnackBar(
      content:
          Text(result is Success<void> ? l.pdfDownloaded : l.pdfError('')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWide =
        MediaQuery.sizeOf(context).width >= CvStyleEditorScreen._wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.customizeCv,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (!isWide)
            TextButton.icon(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(
                  _showPreview ? Icons.tune_rounded : Icons.visibility_rounded,
                  size: 18),
              label: Text(_showPreview ? l.options : l.preview),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Column(
          children: [
            Expanded(child: _panes(isWide)),
            _BottomBar(
              controller: _c,
              isWide: isWide,
              showPreview: _showPreview,
              downloading: _downloading,
              onTogglePreview: () =>
                  setState(() => _showPreview = !_showPreview),
              onDownload: _download,
            ),
          ],
        ),
      ),
    );
  }

  Widget _panes(bool isWide) {
    final options = CvStyleOptionsPane(style: _c.style, onSelect: _c.select);
    final preview = CvStylePreviewPane(styledCv: _styledCv);
    if (!isWide) return _showPreview ? preview : options;
    return Row(
      children: [
        SizedBox(width: _optionsWidth, child: options),
        GestureDetector(
          onHorizontalDragUpdate: (d) => setState(() {
            _optionsWidth = (_optionsWidth + d.delta.dx)
                .clamp(200.0, MediaQuery.sizeOf(context).width * 0.5);
          }),
          child: const CvStyleDraggableDivider(),
        ),
        Expanded(child: preview),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.isWide,
    required this.showPreview,
    required this.downloading,
    required this.onTogglePreview,
    required this.onDownload,
  });

  final CvStyleController controller;
  final bool isWide;
  final bool showPreview;
  final bool downloading;
  final VoidCallback onTogglePreview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = controller.style.primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.saving || controller.hasError) ...[
            Row(
              children: [
                if (controller.saving)
                  SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent))
                else
                  Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(controller.saving ? l.savingShort : l.styleNotSaved,
                    style: TextStyle(
                        fontSize: 12,
                        color: controller.saving
                            ? colorScheme.onSurface.withValues(alpha: 0.65)
                            : colorScheme.error)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (!isWide) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTogglePreview,
                    icon: Icon(
                        showPreview
                            ? Icons.tune_rounded
                            : Icons.visibility_rounded,
                        size: 18),
                    label: Text(showPreview ? l.options : l.preview),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: accent),
                      foregroundColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: downloading ? null : onDownload,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(l.downloadPdf),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
