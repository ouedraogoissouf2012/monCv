import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/error/result.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_status_provider.dart';
import '../providers/cv_provider.dart';
import '../services/ai_service.dart';
import '../utils/error_helper.dart';
import 'ai_button.dart';
import 'application_messages_sheet.dart';

/// Bottom sheet pour analyser la correspondance CV / offre d'emploi.
/// Permet aussi de creer une variante du CV adaptee a l'offre.
class JobMatchSheet extends StatefulWidget {
  final int cvId;
  const JobMatchSheet({super.key, required this.cvId});

  @override
  State<JobMatchSheet> createState() => _JobMatchSheetState();
}

class _JobMatchSheetState extends State<JobMatchSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _creatingVariant = false;
  bool _aiConsentAccepted = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _createVariant() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _creatingVariant = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final variant = await context.read<CvProvider>().createVariant(
            widget.cvId,
            _controller.text.trim(),
          );
      if (!mounted) return;
      if (variant != null) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.variantCreated(variant.varianteLabel ?? '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        setState(() => _creatingVariant = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.variantCreationError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingVariant = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l.errorWithDetails(e.toString().replaceAll('Exception: ', '')),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context)!;
    if (_controller.text.trim().length < 20) {
      setState(() => _error = l.jobOfferTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await AiCvService().matchJob(
        widget.cvId,
        _controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on AiException catch (e) {
      // Erreur IA typee : message precis au lieu de "mode hors ligne"
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (!mounted) return;
      final status = context.read<AiStatusProvider>();
      status.recordError(e);
      status.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException
            ? e.message
            : ErrorHelper.friendlyMessage(context, e.toString());
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l.adaptToJob,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.adaptToJobDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 16),

            if (_result == null) ...[
              // Input
              TextFormField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: l.jobOfferHint,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aiConsentAccepted,
                      onChanged: (value) => setState(() {
                        _aiConsentAccepted = value ?? false;
                      }),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.jobMatchConsent,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AiButton(
                  onPressed: _analyze,
                  enabled: _aiConsentAccepted,
                  loading: _loading,
                  icon: const Icon(Icons.analytics_outlined),
                  label: _loading ? l.analyzing : l.analyzeMatch,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],
            ] else ...[
              // Score
              _ScoreCard(score: _result!['score'] as int? ?? 0),
              const SizedBox(height: 16),

              // Mots-cles presents
              if (_result!['matchedKeywords'] != null &&
                  (_result!['matchedKeywords'] as List).isNotEmpty) ...[
                _KeywordSection(
                  title: l.matchedKeywords,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  keywords: List<String>.from(_result!['matchedKeywords']),
                ),
                const SizedBox(height: 12),
              ],

              // Mots-cles manquants
              if (_result!['missingKeywords'] != null &&
                  (_result!['missingKeywords'] as List).isNotEmpty) ...[
                _KeywordSection(
                  title: l.missingKeywords,
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFEF4444),
                  keywords: List<String>.from(_result!['missingKeywords']),
                ),
                const SizedBox(height: 12),
              ],

              // Suggestions
              if (_result!['suggestions'] != null &&
                  (_result!['suggestions'] as List).isNotEmpty) ...[
                Text(
                  l.suggestions,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                ...List<String>.from(_result!['suggestions']).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '  →  ',
                          style: TextStyle(color: Color(0xFF2563EB)),
                        ),
                        Expanded(
                          child: Text(s, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    builder: (_) => ApplicationMessagesSheet(
                      cvId: widget.cvId,
                      jobDescription: _controller.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l.prepareApplicationMessages),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Bouton creer variante
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _creatingVariant ? null : _createVariant,
                  icon: _creatingVariant
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high_rounded),
                  label: Text(
                    _creatingVariant
                        ? l.creatingVariant
                        : l.createAdaptedVariant,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Bouton re-analyser
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: Text(l.analyzeAnotherOffer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = score >= 70
        ? const Color(0xFF10B981)
        : score >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final label = score >= 70
        ? l.goodMatch
        : score >= 40
            ? l.averageMatch
            : l.lowMatch;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.jobMatchScore,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  const _KeywordSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keywords
              .map(
                (k) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    k,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
