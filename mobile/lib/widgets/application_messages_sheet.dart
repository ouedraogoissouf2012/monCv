import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/injection_container.dart';
import '../features/ai/application/generate_application_messages_usecase.dart';
import '../features/application_messages/domain/clipboard_copier.dart';
import '../features/application_messages/presentation/application_messages_controller.dart';
import '../features/application_messages/presentation/components/message_components.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_status_provider.dart';
import 'ai_button.dart';

/// Feuille de generation des messages de candidature (issue #245, G5).
///
/// Orchestrateur mince : la logique (generation typee, erreurs, copie) vit dans
/// [ApplicationMessagesController]. Cette sheet assemble les composants et
/// reagit a l'etat. Remplace le monolithe de 325 lignes.
class ApplicationMessagesSheet extends StatefulWidget {
  const ApplicationMessagesSheet({
    super.key,
    required this.cvId,
    required this.jobDescription,
    this.scrollController,
  });

  final int cvId;
  final String jobDescription;

  /// Controleur fourni par un [DraggableScrollableSheet] parent (cadrage web).
  final ScrollController? scrollController;

  @override
  State<ApplicationMessagesSheet> createState() =>
      _ApplicationMessagesSheetState();
}

class _ApplicationMessagesSheetState extends State<ApplicationMessagesSheet> {
  late final AiStatusProvider _aiStatus;
  late final ApplicationMessagesController _controller;

  @override
  void initState() {
    super.initState();
    _aiStatus = context.read<AiStatusProvider>();
    _controller = ApplicationMessagesController(
      cvId: widget.cvId,
      jobDescription: widget.jobDescription,
      generate: sl<GenerateApplicationMessagesUseCase>(),
      clipboard: const SystemClipboardCopier(),
      onAiError: (e) => _aiStatus
        ..recordError(e)
        ..refresh(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy(MessageKind kind) async {
    final copied = await _controller.copy(kind);
    if (!mounted || !copied) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.applicationMessageCopied),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            const SizedBox(height: 10),
            MessageSheetHandle(
                color: colorScheme.onSurface.withValues(alpha: 0.2)),
            const MessageSheetHeader(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _body(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final messages = _controller.messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.chooseTone,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        MessageToneSelector(
          tones: ApplicationMessagesController.tones,
          selected: _controller.tone,
          enabled: !_controller.loading,
          onSelected: _controller.selectTone,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: AiButton(
            onPressed: _controller.generate,
            loading: _controller.loading,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: _controller.loading
                ? l.generatingApplicationMessages
                : l.generateApplicationMessages,
          ),
        ),
        if (_controller.error != null) ...[
          const SizedBox(height: 10),
          Text(_controller.error!.message,
              style: TextStyle(color: colorScheme.error)),
        ],
        if (messages != null) ...[
          if (messages.fallback) ...[
            const SizedBox(height: 12),
            MessageStatusBanner(text: l.applicationMessagesFallback),
          ],
          const SizedBox(height: 16),
          MessagePanel(
            title: l.coverLetter,
            icon: Icons.description_outlined,
            text: _controller.textOf(MessageKind.coverLetter),
            initiallyExpanded: true,
            onCopy: () => _copy(MessageKind.coverLetter),
          ),
          MessagePanel(
            title: l.applicationEmail,
            icon: Icons.email_outlined,
            text: _controller.textOf(MessageKind.email),
            initiallyExpanded: false,
            onCopy: () => _copy(MessageKind.email),
          ),
          MessagePanel(
            title: l.linkedInMessage,
            icon: Icons.work_outline_rounded,
            text: _controller.textOf(MessageKind.linkedIn),
            initiallyExpanded: false,
            onCopy: () => _copy(MessageKind.linkedIn),
          ),
          MessagePanel(
            title: l.whatsAppMessage,
            icon: Icons.chat_outlined,
            text: _controller.textOf(MessageKind.whatsApp),
            initiallyExpanded: false,
            onCopy: () => _copy(MessageKind.whatsApp),
          ),
        ],
      ],
    );
  }
}

