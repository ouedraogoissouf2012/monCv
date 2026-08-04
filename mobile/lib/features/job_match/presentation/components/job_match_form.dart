import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../widgets/ai_button.dart';

/// Etat de saisie de la sheet de correspondance : offre + consentement +
/// bouton d'analyse (issue #245, G4). Extrait du monolithe, pilote par le
/// [JobMatchController] via les callbacks.
class JobMatchForm extends StatelessWidget {
  const JobMatchForm({
    super.key,
    required this.controller,
    required this.consentAccepted,
    required this.loading,
    required this.canAnalyze,
    required this.error,
    required this.onConsentChanged,
    required this.onChanged,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final bool consentAccepted;
  final bool loading;
  final bool canAnalyze;
  final String? error;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: 6,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: l.jobOfferHint,
            hintStyle:
                TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: consentAccepted,
                onChanged: (value) => onConsentChanged(value ?? false),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l.jobMatchConsent,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.72))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AiButton(
            onPressed: onAnalyze,
            enabled: canAnalyze,
            loading: loading,
            icon: const Icon(Icons.analytics_outlined),
            label: loading ? l.analyzing : l.analyzeMatch,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!,
              style: TextStyle(color: colorScheme.error, fontSize: 12)),
        ],
      ],
    );
  }
}
