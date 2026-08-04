import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cv.dart';
import '../../models/cv_style.dart';
import '../../providers/cv_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/cv_preview.dart';
import '../../features/ai/domain/entities/enhanced_cv.dart';
import '../../widgets/ai_enhance_sheet.dart';
import '../../widgets/draggable_bottom_sheet.dart';
import '../../widgets/job_match_sheet.dart';

class CvDetailScreen extends StatefulWidget {
  final int cvId;

  const CvDetailScreen({super.key, required this.cvId});

  @override
  State<CvDetailScreen> createState() => _CvDetailScreenState();
}

class _CvDetailScreenState extends State<CvDetailScreen> {
  bool _isDownloadingPdf = false;
  bool _isDownloadingDocx = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvById(widget.cvId);
    });
  }

  Future<void> _downloadPdf(Cv cv) async {
    final l = AppLocalizations.of(context)!;
    if (_isDownloadingPdf) return;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isDownloadingPdf = true);
    try {
      await context.read<PdfService>().downloadPdf(cv);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.pdfDownloaded),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.pdfError(e.toString())),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  Future<void> _downloadDocx(Cv cv) async {
    final l = AppLocalizations.of(context)!;
    if (_isDownloadingDocx) return;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isDownloadingDocx = true);
    try {
      await context.read<PdfService>().downloadDocx(cv.id!);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.docxDownloaded),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l.docxError(e.toString())),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloadingDocx = false);
    }
  }

  Future<void> _openEnhancement(Cv cv, {bool proofreadOnly = false}) async {
    final l = AppLocalizations.of(context)!;
    final provider = context.read<CvProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDraggableBottomSheet<EnhancedCv>(
      context,
      (sc) => AiEnhanceSheet(
        cv: cv,
        proofreadOnly: proofreadOnly,
        scrollController: sc,
      ),
    );
    if (result == null || !mounted) return;

    final ok = await provider.applyEnhancedCv(cv.id!, result);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? proofreadOnly
              ? l.spellingCorrectionsApplied
              : l.aiSuggestionsApplied
          : l.applicationError),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.success : Colors.red,
    ));
  }

  void _openCustomizePanel(BuildContext context, Cv cv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CvStylePage(
          cv: cv,
          onStyleChanged: (newStyle) =>
              context.read<CvProvider>().updateCvStyle(cv.id!, newStyle),
        ),
      ),
    );
  }

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

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              cv.titre,
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.spellcheck_rounded),
                tooltip: l.proofreadSpelling,
                onPressed: () => _openEnhancement(cv, proofreadOnly: true),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded),
                tooltip: l.enhanceWithAi,
                onPressed: () => _openEnhancement(cv),
              ),
              IconButton(
                icon: const Icon(Icons.work_outline_rounded),
                tooltip: l.adaptToJob,
                onPressed: () async {
                  final adapted =
                      await showDraggableBottomSheet<Map<String, dynamic>>(
                    context,
                    (_) => JobMatchSheet(cvId: cv.id!),
                  );
                  if (!context.mounted) return; // Le dialogue est asynchrone.
                  if (adapted != null) {
                    final cvProvider = context.read<CvProvider>();
                    // Dupliquer d'abord
                    final duplicated = await cvProvider.duplicateCv(cv.id!);
                    if (!context.mounted) return;
                    if (duplicated) {
                      // Appliquer les modifications IA sur la copie
                      final newCv = cvProvider.cvs.firstWhere(
                        (c) => c.titre.startsWith('Copie de'),
                        orElse: () => cv,
                      );
                      if (newCv.id != null) {
                        await cvProvider.applyAiEnhancements(
                            newCv.id!, adapted);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.adaptedVariantCreated),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ));
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: l.customize,
                onPressed: () => _openCustomizePanel(context, cv),
              ),
              if (_isDownloadingPdf)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: l.downloadPdf,
                  onPressed: () => _downloadPdf(cv),
                ),
              if (_isDownloadingDocx)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: l.downloadDocx,
                  onPressed: () => _downloadDocx(cv),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.edit,
                onPressed: () => context.push('/cvs/${cv.id}/edit', extra: cv),
              ),
            ],
          ),
          body: CvPreviewWidget(cv: cv),
        );
      },
    );
  }
}

// ── Page plein ecran de personnalisation ─────────────────────────────────────

class _CvStylePage extends StatefulWidget {
  final Cv cv;
  final Future<bool> Function(CvStyle style) onStyleChanged;

  const _CvStylePage({required this.cv, required this.onStyleChanged});

  @override
  State<_CvStylePage> createState() => _CvStylePageState();
}

class _CvStylePageState extends State<_CvStylePage> {
  late CvStyle _style;
  bool _showPreview = false;
  bool _downloading = false;
  bool _savingStyle = false;
  String? _styleError;
  int _saveGeneration = 0;
  double _optionsWidth = 300;

  @override
  void initState() {
    super.initState();
    _style = widget.cv.style;
  }

  Future<void> _apply(CvStyle newStyle) async {
    final generation = ++_saveGeneration;
    setState(() {
      _style = newStyle;
      _savingStyle = true;
      _styleError = null;
    });

    final saved = await widget.onStyleChanged(newStyle);
    if (!mounted || generation != _saveGeneration) {
      return;
    }

    setState(() {
      _savingStyle = false;
      _styleError = saved ? null : AppLocalizations.of(context)!.styleNotSaved;
    });
  }

  Cv get _styledCv => widget.cv.copyWith(style: _style);

  Future<void> _download() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _downloading = true);
    try {
      await context.read<PdfService>().downloadPdf(_styledCv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.pdfDownloaded),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.errorWithDetails(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text(l.customizeCv, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (!isWide)
            TextButton.icon(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(
                _showPreview ? Icons.tune_rounded : Icons.visibility_rounded,
                size: 18,
              ),
              label: Text(_showPreview ? l.options : l.preview),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(
                        width: _optionsWidth,
                        child: _buildOptionsPane(colorScheme),
                      ),
                      GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _optionsWidth = (_optionsWidth + details.delta.dx)
                                .clamp(200.0, screenWidth * 0.5);
                          });
                        },
                        child: const _DraggableDivider(),
                      ),
                      Expanded(child: _buildPreviewPane()),
                    ],
                  )
                : _showPreview
                    ? _buildPreviewPane()
                    : _buildOptionsPane(colorScheme),
          ),
          // Barre du bas
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_savingStyle || _styleError != null) ...[
                  Row(
                    children: [
                      if (_savingStyle)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _style.primaryColor,
                          ),
                        )
                      else
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _savingStyle ? l.savingShort : _styleError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _savingStyle
                              ? colorScheme.onSurface.withValues(alpha: 0.65)
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (!isWide) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showPreview = !_showPreview),
                          icon: Icon(
                            _showPreview
                                ? Icons.tune_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                          ),
                          label: Text(_showPreview ? l.options : l.preview),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _style.primaryColor),
                            foregroundColor: _style.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _downloading ? null : _download,
                        style: FilledButton.styleFrom(
                          backgroundColor: _style.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download_rounded, size: 20),
                        label: Text(l.downloadPdf),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPane() {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.previewSurface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _style.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _style.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${CvStyle.templates.firstWhere((t) => t.id == _style.templateId).label} / ${_style.fontFamily}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _style.primaryColor),
                  ),
                ),
                const Spacer(),
                Text(l.livePreview,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CvPreviewWidget(cv: _styledCv),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPane(ColorScheme colorScheme) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Templates en grille 2 colonnes
        _optionLabel(l.template, colorScheme),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: CvStyle.templates.map((t) {
            final selected = _style.templateId == t.id;
            return GestureDetector(
              onTap: () => _apply(_style.copyWith(templateId: t.id)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? _style.primaryColor
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? _style.primaryColor.withValues(alpha: 0.06)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        color: t.previewColor, size: 16),
                    const SizedBox(width: 6),
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Couleurs
        _optionLabel(l.color, colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CvStyle.paletteColors.map((c) {
            final selected = _style.primaryColor.toARGB32() == c.toARGB32();
            return GestureDetector(
              onTap: () => _apply(_style.copyWith(primaryColor: c)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: colorScheme.onSurface, width: 2.5)
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Police
        _optionLabel(l.font, colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CvStyle.fontFamilies.map((f) {
            final selected = _style.fontFamily == f;
            return GestureDetector(
              onTap: () => _apply(_style.copyWith(fontFamily: f)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? _style.primaryColor
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                  color: selected
                      ? _style.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 11,
                        color: selected ? _style.primaryColor : null,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _optionLabel(String text, ColorScheme colorScheme) {
    return Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ));
  }
}

// ── Separateur draggable ────────────────────────────────────────

class _DraggableDivider extends StatefulWidget {
  const _DraggableDivider();

  @override
  State<_DraggableDivider> createState() => _DraggableDividerState();
}

class _DraggableDividerState extends State<_DraggableDivider> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 16,
        color: _hovering
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.05),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _hovering ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _hovering ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _hovering ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
