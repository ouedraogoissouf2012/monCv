import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/injection_container.dart';
import '../core/error/result.dart';
import '../features/ai/application/match_job_usecase.dart';
import '../features/job_match/presentation/components/job_match_form.dart';
import '../features/job_match/presentation/components/job_match_result.dart';
import '../features/cv/presentation/cv_store.dart';
import '../features/job_match/presentation/job_match_controller.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_status_provider.dart';
import '../usecases/cv/create_variant_usecase.dart';
import '../utils/app_colors.dart';
import 'application_messages_sheet.dart';

/// Bottom sheet pour analyser la correspondance CV / offre d'emploi et creer
/// une variante du CV adaptee (issue #245, G4).
///
/// Orchestrateur mince : toute la logique (validation, appel IA, historique,
/// invariant "une variante par analyse", erreurs typees) vit dans
/// [JobMatchController]. Cette sheet ne fait qu'assembler les composants
/// ([JobMatchForm], [JobMatchResult]) et reagir a l'etat. Elle remplace le
/// monolithe de 1018 lignes.
class JobMatchSheet extends StatefulWidget {
  final int cvId;
  const JobMatchSheet({super.key, required this.cvId});

  @override
  State<JobMatchSheet> createState() => _JobMatchSheetState();
}

class _JobMatchSheetState extends State<JobMatchSheet> {
  final _textController = TextEditingController();
  late final AiStatusProvider _aiStatus;
  late final JobMatchController _controller;

  @override
  void initState() {
    super.initState();
    _aiStatus = context.read<AiStatusProvider>();
    _controller = JobMatchController(
      cvId: widget.cvId,
      matchJob: sl<MatchJobUseCase>(),
      createVariant: sl<CreateVariantUseCase>(),
      store: sl<CvStore>(),
      onAiError: _reportAiError,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _reportAiError(AiException error) {
    _aiStatus
      ..recordError(error)
      ..refresh();
  }

  Future<void> _createVariant() async {
    await _controller.createVariant();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    // Comportement identique au monolithe : au succes, on ferme la sheet et on
    // confirme ; sinon on reste ouvert avec un message d'erreur.
    if (_controller.variantCreated) {
      Navigator.of(context).pop();
      final notes = _controller.variant?.refusedNotes ?? const [];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(notes.isEmpty
            ? l.variantCreated(_controller.variant?.label ?? '')
            : '${l.variantCreated(_controller.variant?.label ?? '')} ${l.variantFidelityBlocked}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ));
    } else if (_controller.variantError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.variantCreationError),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openApplicationMessages() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => ApplicationMessagesSheet(
        cvId: widget.cvId,
        jobDescription: _textController.text.trim(),
      ),
    );
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
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 16),
              const _SheetHeader(),
              const SizedBox(height: 16),
              if (_controller.report == null)
                JobMatchForm(
                  controller: _textController,
                  consentAccepted: _controller.consentAccepted,
                  loading: _controller.loading,
                  canAnalyze: _controller.canAnalyze,
                  error: _controller.error?.message,
                  onConsentChanged: _controller.setConsent,
                  onChanged: _controller.setJobDescription,
                  onAnalyze: _controller.analyze,
                )
              else
                JobMatchResult(
                  report: _controller.report!,
                  history: _controller.history,
                  creatingVariant: _controller.creatingVariant,
                  onCreateVariant:
                      _controller.canCreateVariant ? _createVariant : null,
                  onPrepareMessages: _openApplicationMessages,
                  onAnalyzeAnother: _controller.reset,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work_outline_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(l.adaptToJob,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(l.adaptToJobDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55))),
      ],
    );
  }
}
