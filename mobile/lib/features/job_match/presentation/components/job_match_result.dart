import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../ai/domain/entities/job_match.dart';
import '../../domain/job_score_snapshot.dart';
import 'job_detail_cards.dart';
import 'job_history_keywords.dart';
import 'job_score_card.dart';

/// Etat "resultats" de la sheet de correspondance : score, historique,
/// categories, plan d'action, controles de format, mots-cles, actions
/// (issue #245, G4). Branche sur le rapport TYPE [JobMatch] et les composants
/// extraits en G2 — plus aucune `Map<String, dynamic>`.
class JobMatchResult extends StatelessWidget {
  const JobMatchResult({
    super.key,
    required this.report,
    required this.history,
    required this.creatingVariant,
    required this.onCreateVariant,
    required this.onPrepareMessages,
    required this.onAnalyzeAnother,
  });

  final JobMatch report;
  final List<JobScoreSnapshot> history;
  final bool creatingVariant;
  final VoidCallback? onCreateVariant;
  final VoidCallback onPrepareMessages;
  final VoidCallback onAnalyzeAnother;

  /// Nombre de colonnes de la grille de categories.
  static const int _categoryColumns = 2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.fallback) _FallbackNotice(message: l.fallbackResult),
        JobScoreCard(score: report.score),
        const SizedBox(height: 16),
        if (history.isNotEmpty) ...[
          JobSectionTitle(title: l.atsScoreHistory),
          const SizedBox(height: 8),
          JobHistoryCard(history: history),
          const SizedBox(height: 16),
        ],
        if (report.categories.isNotEmpty) ...[
          JobSectionTitle(title: l.atsCategoryBreakdown),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _categoryColumns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) =>
                JobCategoryCard(category: report.categories[index]),
          ),
          const SizedBox(height: 16),
        ],
        if (report.prioritizedRecommendations.isNotEmpty) ...[
          JobSectionTitle(title: l.atsActionPlan),
          const SizedBox(height: 8),
          JobRecommendationCard(
              recommendations: report.prioritizedRecommendations),
          const SizedBox(height: 16),
        ],
        JobSectionTitle(title: l.atsFormatChecks),
        const SizedBox(height: 8),
        JobFormatChecksCard(formatChecks: report.formatChecks),
        const SizedBox(height: 16),
        if (report.matchedKeywords.isNotEmpty) ...[
          JobKeywordSection(
            title: l.matchedKeywords,
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            keywords: report.matchedKeywords,
          ),
          const SizedBox(height: 12),
        ],
        if (report.missingKeywords.isNotEmpty) ...[
          JobKeywordSection(
            title: l.missingKeywords,
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
            keywords: report.missingKeywords,
          ),
          const SizedBox(height: 12),
        ],
        if (report.suggestions.isNotEmpty) ...[
          JobSectionTitle(title: l.suggestions),
          const SizedBox(height: 6),
          ...report.suggestions.map(_SuggestionRow.new),
          const SizedBox(height: 12),
        ],
        _JobMatchActions(
          creatingVariant: creatingVariant,
          onCreateVariant: onCreateVariant,
          onPrepareMessages: onPrepareMessages,
          onAnalyzeAnother: onAnalyzeAnother,
        ),
      ],
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.arrow_right_alt_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}

class _JobMatchActions extends StatelessWidget {
  const _JobMatchActions({
    required this.creatingVariant,
    required this.onCreateVariant,
    required this.onPrepareMessages,
    required this.onAnalyzeAnother,
  });

  final bool creatingVariant;
  final VoidCallback? onCreateVariant;
  final VoidCallback onPrepareMessages;
  final VoidCallback onAnalyzeAnother;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPrepareMessages,
            icon: const Icon(Icons.send_rounded),
            label: Text(l.prepareApplicationMessages),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: creatingVariant ? null : onCreateVariant,
            icon: creatingVariant
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: Text(
                creatingVariant ? l.creatingVariant : l.createOptimizedVariant),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onAnalyzeAnother,
            child: Text(l.analyzeAnotherOffer),
          ),
        ),
      ],
    );
  }
}
