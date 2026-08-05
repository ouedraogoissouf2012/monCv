import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/cv.dart';
import '../../../../models/cv_style.dart';
import '../../../../utils/app_colors.dart';
import '../../../../widgets/cv_preview.dart';

/// Panneau d'apercu live du CV pendant l'edition du style (issue #247, B4a).
/// Extrait de `_buildPreviewPane`. Affiche le CV stylé et un badge template/police.
class CvStylePreviewPane extends StatelessWidget {
  const CvStylePreviewPane({super.key, required this.styledCv});

  /// Le CV avec le style courant applique (`cv.copyWith(style: ...)`).
  final Cv styledCv;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = styledCv.style;
    final templateLabel =
        CvStyle.templates.firstWhere((t) => t.id == style.templateId).label;
    return Container(
      color: AppColors.previewSurface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: style.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text('$templateLabel / ${style.fontFamily}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: style.primaryColor)),
                ),
                const Spacer(),
                Text(l.livePreview,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CvPreviewWidget(cv: styledCv),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
