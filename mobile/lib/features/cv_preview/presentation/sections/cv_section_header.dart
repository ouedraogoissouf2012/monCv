import 'package:flutter/material.dart';

import '../theme/cv_document_theme.dart';

/// En-tete de section partage par les templates de preview (issue #243).
///
/// Barre d'accent + titre en capitales + trait de separation. Extrait du
/// monolithe `cv_preview.dart` (`_sectionTitle`), puise ses jetons dans
/// [CvDocumentTheme] plutot que des litteraux.
class CvSectionHeader extends StatelessWidget {
  const CvSectionHeader({
    super.key,
    required this.title,
    required this.accent,
  });

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: CvDocumentTheme.sizeSectionTitle,
                fontWeight: CvDocumentTheme.weightSectionTitle,
                color: accent,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.5,
              color: accent.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
