import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';

/// Feuille de suggestions IA : liste des propositions, chaque tap ajoute la
/// suggestion (en puce) au [controller] fourni puis ferme la feuille
/// (issue #239).
///
/// Deplacee depuis `screens/cv/sections/experience_section.dart` vers
/// `features/cv/presentation` car partagee par plusieurs sections
/// (experience, projets) : une primitive reutilisable ne doit pas vivre dans
/// une section particuliere.
Future<void> showSuggestionsSheet(
  BuildContext context,
  List<String> suggestions,
  TextEditingController controller,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text(
                  l.aiSuggestions,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l.tapSuggestion,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral450),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => InkWell(
                onTap: () {
                  final current = controller.text.trim();
                  controller.text = current.isEmpty
                      ? '• ${suggestions[i]}'
                      : '$current\n• ${suggestions[i]}';
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('• ${suggestions[i]}',
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
