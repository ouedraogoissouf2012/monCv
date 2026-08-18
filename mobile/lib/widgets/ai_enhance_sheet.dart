import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/injection_container.dart';
import '../features/ai/application/enhance_cv_usecase.dart';
import '../features/ai/domain/entities/enhanced_cv.dart';
import '../features/ai_enhancement/domain/enhancement_level.dart';
import '../features/ai_enhancement/presentation/components/consent_notice.dart';
import '../features/ai_enhancement/presentation/components/enhancement_result_list.dart';
import '../features/ai_enhancement/presentation/components/enhancement_sheet_parts.dart';
import '../features/ai_enhancement/presentation/components/level_selector.dart';
import '../features/ai_enhancement/presentation/components/status_banner.dart';
import '../features/ai_enhancement/presentation/enhancement_controller.dart';
import '../l10n/app_localizations.dart';
import '../features/cv/presentation/cv_presentation_model.dart';
import '../providers/ai_status_provider.dart';
import '../utils/app_colors.dart';
import 'ai_button.dart';

/// Feuille d'amelioration IA d'un CV (issue #244).
///
/// Orchestrateur : compose [EnhancementController] (etat + use case typé) et
/// des composants courts. Ne connait plus le transport ni les
/// `Map<String, dynamic>` : le resultat est l'entite [EnhancedCv], retournee via
/// `Navigator.pop` a l'appelant qui l'applique par la voie typee (F4a).
class AiEnhanceSheet extends StatefulWidget {
  const AiEnhanceSheet({
    super.key,
    required this.cv,
    this.initialLevel = EnhancementLevel.medium,
    this.proofreadOnly = false,
    this.scrollController,
  });

  final Cv cv;
  final EnhancementLevel initialLevel;
  final bool proofreadOnly;

  /// Controleur fourni par un [DraggableScrollableSheet] parent : quand il est
  /// present, le scroll interne est pilote par le drag de la feuille (evite un
  /// conflit de defilement et le debordement en bas d'ecran sur web).
  final ScrollController? scrollController;

  @override
  State<AiEnhanceSheet> createState() => _AiEnhanceSheetState();
}

class _AiEnhanceSheetState extends State<AiEnhanceSheet> {
  late final EnhancementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EnhancementController(
      cv: widget.cv,
      enhanceCv: sl<EnhanceCvUseCase>(),
      proofreadOnly: widget.proofreadOnly,
      initialLevel: widget.initialLevel,
      onAiError: (e) {
        if (!mounted) return;
        context.read<AiStatusProvider>()
          ..recordError(e)
          ..refresh();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              EnhancementHeader(proofreadOnly: widget.proofreadOnly),
              const SizedBox(height: 20),
              if (_controller.result == null)
                ..._buildForm(context)
              else
                ..._buildResult(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      if (widget.proofreadOnly)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(l.proofreadingGuarantee,
              style: const TextStyle(fontSize: 12, height: 1.35)),
        )
      else
        LevelSelector(
          selected: _controller.level,
          enabled: !_controller.loading,
          onSelected: _controller.selectLevel,
        ),
      const SizedBox(height: 16),
      ConsentNotice(
        accepted: _controller.consentAccepted,
        onChanged: _controller.setConsent,
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: AiButton(
          onPressed: _controller.enhance,
          enabled: _controller.canEnhance,
          loading: _controller.loading,
          icon: Icon(widget.proofreadOnly
              ? Icons.spellcheck_rounded
              : Icons.auto_awesome_rounded),
          label: _controller.loading
              ? l.proofreadingInProgress
              : widget.proofreadOnly
                  ? l.proofreadCv
                  : l.improve,
          style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
        ),
      ),
      if (_controller.error != null) ...[
        const SizedBox(height: 12),
        EnhancementErrorBanner(message: _controller.error!.message),
      ],
    ];
  }

  List<Widget> _buildResult(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final result = _controller.result!;
    return [
      StatusBanner(aiGenerated: result.aiGenerated),
      const SizedBox(height: 12),
      if (_controller.changes.isEmpty)
        _AlreadyCorrectedNotice(message: l.noCertainCorrection)
      else
        EnhancementResultList(changes: _controller.changes),
      const SizedBox(height: 16),
      if (_controller.changes.isEmpty)
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop<EnhancedCv>(),
            child: Text(l.close),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _controller.enhance,
                child: Text(l.retry),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop<EnhancedCv>(result),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.apply),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
              ),
            ),
          ],
        ),
    ];
  }
}

class _AlreadyCorrectedNotice extends StatelessWidget {
  const _AlreadyCorrectedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
