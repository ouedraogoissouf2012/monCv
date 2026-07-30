import 'package:flutter/material.dart';

import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../ai/application/generate_resume_usecase.dart';
import '../../domain/policies/cv_validation_thresholds.dart';
import 'personal_info_form_controller.dart';

/// Champ « Resume professionnel » avec generation IA (issue #242).
///
/// La generation passe par [GenerateResumeUseCase] (port AiRepository), jamais
/// par le transport direct. Le consentement est requis avant tout appel. Le
/// seuil de longueur "resume trop court" vient de [CvValidationThresholds]
/// (`minSummaryLength`), plus de valeur codee en dur dans le widget.
class AiResumeField extends StatefulWidget {
  const AiResumeField({
    super.key,
    required this.controller,
    required this.generateResume,
    required this.onChanged,
  });

  final PersonalInfoFormController controller;
  final GenerateResumeUseCase generateResume;
  final VoidCallback onChanged;

  @override
  State<AiResumeField> createState() => _AiResumeFieldState();
}

class _AiResumeFieldState extends State<AiResumeField> {
  bool _loading = false;
  bool _consent = false;

  Future<void> _generate() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    final result = await widget.generateResume(GenerateResumeParams(
      titrePoste: widget.controller.titrePoste.text,
    ));
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success(:final data):
        setState(() => widget.controller.resume.text = data);
        widget.onChanged();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.summaryGenerated),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.errorAiUnavailable),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = widget.controller.resume.text;
    final tooShort =
        text.isNotEmpty && text.length < CvValidationThresholds.minSummaryLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              visualDensity: VisualDensity.compact,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(l.aiPersonalDataConsent,
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
        TextButton.icon(
          key: const Key('ai-generate-button'),
          onPressed: _loading || !_consent ? null : _generate,
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome_rounded, size: 16),
          label: Text(_loading ? l.generating : l.generateWithAi,
              style: const TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            foregroundColor: AppColors.violet,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller.resume,
          decoration: InputDecoration(
            labelText: l.professionalSummary,
            hintText:
                'Ex : Developpeur Full Stack avec 3 ans d\'experience...',
            alignLabelWithHint: true,
            helperText: text.isEmpty
                ? l.generateSummaryHelper
                : tooShort
                    ? l.resumeTooShort
                    : '${l.goodResume} (${text.length} ${l.characters})',
            helperStyle: TextStyle(
              color: text.isEmpty
                  ? null
                  : tooShort
                      ? AppColors.error
                      : AppColors.success,
              fontWeight: tooShort ? FontWeight.w600 : null,
            ),
          ),
          maxLines: 4,
          onChanged: (_) {
            widget.onChanged();
            setState(() {});
          },
        ),
      ],
    );
  }
}
