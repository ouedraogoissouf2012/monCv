import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/error/result.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_status_provider.dart';
import '../services/ai_service.dart';
import '../utils/error_helper.dart';
import 'ai_button.dart';

class ApplicationMessagesSheet extends StatefulWidget {
  const ApplicationMessagesSheet({
    super.key,
    required this.cvId,
    required this.jobDescription,
  });

  final int cvId;
  final String jobDescription;

  @override
  State<ApplicationMessagesSheet> createState() =>
      _ApplicationMessagesSheetState();
}

class _ApplicationMessagesSheetState extends State<ApplicationMessagesSheet> {
  String _tone = 'PROFESSIONAL';
  bool _loading = false;
  Map<String, dynamic>? _messages;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AiCvService().generateApplicationMessages(
        widget.cvId,
        widget.jobDescription,
        _tone,
      );
      if (!mounted) return;
      setState(() {
        _messages = result;
        _loading = false;
      });
    } on AiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
      final status = context.read<AiStatusProvider>();
      status.recordError(error);
      status.refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppException
            ? error.message
            : ErrorHelper.friendlyMessage(context, error.toString());
        _loading = false;
      });
    }
  }

  Future<void> _copy(String text) async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.applicationMessageCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final toneLabels = <String, String>{
      'SIMPLE': l.toneSimple,
      'PROFESSIONAL': l.toneProfessional,
      'DIRECT': l.toneDirect,
      'JUNIOR': l.toneJunior,
      'SENIOR': l.toneSenior,
    };

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.applicationMessagesTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          l.applicationMessagesSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.chooseTone,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: toneLabels.entries
                            .map(
                              (entry) => ButtonSegment<String>(
                                value: entry.key,
                                label: Text(entry.value),
                              ),
                            )
                            .toList(),
                        selected: {_tone},
                        onSelectionChanged: _loading
                            ? null
                            : (selection) => setState(() {
                                _tone = selection.first;
                                _messages = null;
                              }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: AiButton(
                        onPressed: _generate,
                        loading: _loading,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: _loading
                            ? l.generatingApplicationMessages
                            : l.generateApplicationMessages,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                    ],
                    if (_messages != null) ...[
                      if (_messages!['fallback'] == true) ...[
                        const SizedBox(height: 12),
                        _StatusBanner(text: l.applicationMessagesFallback),
                      ],
                      const SizedBox(height: 16),
                      _MessagePanel(
                        title: l.coverLetter,
                        icon: Icons.description_outlined,
                        text: _messages!['coverLetter'] as String? ?? '',
                        onCopy: _copy,
                      ),
                      _MessagePanel(
                        title: l.applicationEmail,
                        icon: Icons.email_outlined,
                        text: _messages!['email'] as String? ?? '',
                        onCopy: _copy,
                      ),
                      _MessagePanel(
                        title: l.linkedInMessage,
                        icon: Icons.work_outline_rounded,
                        text: _messages!['linkedIn'] as String? ?? '',
                        onCopy: _copy,
                      ),
                      _MessagePanel(
                        title: l.whatsAppMessage,
                        icon: Icons.chat_outlined,
                        text: _messages!['whatsApp'] as String? ?? '',
                        onCopy: _copy,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.onTertiaryContainer, fontSize: 12),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.icon,
    required this.text,
    required this.onCopy,
  });

  final String title;
  final IconData icon;
  final String text;
  final Future<void> Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: title == l.coverLetter,
        leading: Icon(icon, size: 20, color: colors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        trailing: IconButton(
          tooltip: l.copy,
          onPressed: () => onCopy(text),
          icon: const Icon(Icons.copy_rounded, size: 19),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
