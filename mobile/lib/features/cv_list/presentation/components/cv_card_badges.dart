import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../../utils/app_colors.dart';

/// Badges d'etat en tete de carte CV (issue #249, D3) : variante et/ou CV cree
/// hors ligne non synchronise. Extraits du monolithe (cv_card.dart:70-136).
class CvCardBadges extends StatelessWidget {
  const CvCardBadges({super.key, required this.cv});

  final Cv cv;

  bool get _isUnsynced => cv.id != null && cv.id! < 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!cv.isVariante && !_isUnsynced) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cv.isVariante) ...[
          _Badge(
            icon: Icons.tune_rounded,
            color: AppColors.primary,
            text: '${l.variant} — ${cv.varianteLabel ?? ''}',
          ),
          const SizedBox(height: 6),
        ],
        if (_isUnsynced) ...[
          _Badge(
            icon: Icons.cloud_off_rounded,
            color: AppColors.warning,
            text: l.pendingSync,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
