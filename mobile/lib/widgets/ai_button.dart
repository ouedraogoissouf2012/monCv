import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ai_status_provider.dart';

/// Bouton IA reutilisable qui reflete l'etat reel du fournisseur.
class AiButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool loading;
  final bool enabled;
  final ButtonStyle? style;

  const AiButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.loading = false,
    this.enabled = true,
    this.style,
  });

  @override
  State<AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<AiButton> {
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<AiStatusProvider>().retryAfter != null) {
        context.read<AiStatusProvider>().clearExpiredRetry();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AiStatusProvider>();
    final canRun = widget.enabled && status.canUseAi && !widget.loading;
    final reason = status.unavailableReason;
    final button = FilledButton.icon(
      onPressed: canRun ? widget.onPressed : null,
      icon: widget.loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.icon,
      label: Text(widget.label),
      style: widget.style,
    );

    if (reason == null) return button;
    return Tooltip(message: reason, child: button);
  }
}
