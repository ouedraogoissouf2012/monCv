import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/error/result.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_status_provider.dart';
import '../providers/cv_provider.dart';
import '../services/ai_service.dart';
import '../utils/error_helper.dart';
import 'ai_button.dart';

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
  final List<_ScoreSnapshot> _history = [];

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
      final score = result['score'] as int? ?? 0;
      setState(() {
        _result = result;
        _loading = false;
        _history.insert(
          0,
          _ScoreSnapshot(
            score: score,
            createdAt: DateTime.now(),
            label: _history.isEmpty ? l.atsCurrentRun : l.atsRerunLabel,
          ),
        );
        if (_history.length > 4) {
          _history.removeRange(4, _history.length);
        }
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
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

  List<Map<String, dynamic>> _mapList(String key) {
    final raw = _result?[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _stringList(String key) {
    final raw = _result?[key];
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
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
    final categories = _mapList('categories');
    final recommendations = _mapList('prioritizedRecommendations');
    final formatChecks = _mapList('formatChecks');
    final matchedKeywords = _stringList('matchedKeywords');
    final missingKeywords = _stringList('missingKeywords');
    final suggestions = _stringList('suggestions');
    final fallback = _result?['fallback'] == true;

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
              if (fallback) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.fallbackResult,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _ScoreCard(score: _result!['score'] as int? ?? 0),
              const SizedBox(height: 16),
              if (_history.isNotEmpty) ...[
                _SectionTitle(title: l.atsScoreHistory),
                const SizedBox(height: 8),
                _HistoryCard(history: _history),
                const SizedBox(height: 16),
              ],
              if (categories.isNotEmpty) ...[
                _SectionTitle(title: l.atsCategoryBreakdown),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) => _CategoryCard(
                    category: categories[index],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (recommendations.isNotEmpty) ...[
                _SectionTitle(title: l.atsActionPlan),
                const SizedBox(height: 8),
                _RecommendationCard(recommendations: recommendations),
                const SizedBox(height: 16),
              ],
              _SectionTitle(title: l.atsFormatChecks),
              const SizedBox(height: 8),
              _FormatChecksCard(formatChecks: formatChecks),
              const SizedBox(height: 16),
              if (matchedKeywords.isNotEmpty) ...[
                _KeywordSection(
                  title: l.matchedKeywords,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  keywords: matchedKeywords,
                ),
                const SizedBox(height: 12),
              ],
              if (missingKeywords.isNotEmpty) ...[
                _KeywordSection(
                  title: l.missingKeywords,
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFEF4444),
                  keywords: missingKeywords,
                ),
                const SizedBox(height: 12),
              ],
              if (suggestions.isNotEmpty) ...[
                _SectionTitle(title: l.suggestions),
                const SizedBox(height: 6),
                ...suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                        : l.createOptimizedVariant,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
            width: 64,
            height: 64,
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
          const SizedBox(width: 18),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final score = category['score'] as int? ?? 0;
    final label = category['label']?.toString() ?? '';
    final summary = category['summary']?.toString() ?? '';
    final evidence = (category['evidence'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList();
    final color = score >= 70
        ? const Color(0xFF10B981)
        : score >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
              ),
            ),
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: evidence
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  const _RecommendationCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: recommendations.map((recommendation) {
          final keywords =
              (recommendation['keywords'] as List<dynamic>? ?? const [])
                  .map((item) => item.toString())
                  .where((item) => item.isNotEmpty)
                  .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${recommendation['priority'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation['description']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      if (keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: keywords
                              .map(
                                (keyword) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FormatChecksCard extends StatelessWidget {
  final List<Map<String, dynamic>> formatChecks;
  const _FormatChecksCard({required this.formatChecks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (formatChecks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          l.atsNoFormatRisk,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    return Column(
      children: formatChecks.map((item) {
        final severity = item['severity']?.toString() ?? 'info';
        final config = switch (severity) {
          'critical' => (
              color: const Color(0xFFEF4444),
              icon: Icons.error_outline_rounded,
            ),
          'warning' => (
              color: const Color(0xFFF59E0B),
              icon: Icons.warning_amber_rounded,
            ),
          _ => (
              color: const Color(0xFF2563EB),
              icon: Icons.info_outline_rounded,
            ),
        };
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.color.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(config.icon, size: 18, color: config.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: config.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['detail']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<_ScoreSnapshot> history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final item = entry.value;
          final diff = entry.key == history.length - 1
              ? null
              : item.score - history[entry.key + 1].score;
          final diffColor = (diff ?? 0) >= 0
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.score}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (diff != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    diff >= 0 ? '+$diff' : '$diff',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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

class _ScoreSnapshot {
  final int score;
  final DateTime createdAt;
  final String label;

  const _ScoreSnapshot({
    required this.score,
    required this.createdAt,
    required this.label,
  });
}
