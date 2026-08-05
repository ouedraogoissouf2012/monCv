import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Barre d'actions basse d'une carte CV (issue #249, D3) : voir, partager,
/// export PDF/DOCX. Extraite du monolithe (cv_card.dart:305-341).
class CvCardActions extends StatelessWidget {
  const CvCardActions({
    super.key,
    required this.onView,
    required this.onShare,
    required this.onDownloadPdf,
    required this.onDownloadDocx,
  });

  final VoidCallback onView;
  final VoidCallback onShare;
  final VoidCallback onDownloadPdf;
  final VoidCallback onDownloadDocx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8)),
            child: Text(l.view),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
            onPressed: onShare,
            tooltip: l.share,
            icon: const Icon(Icons.share_outlined)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onDownloadPdf,
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
          child: Text(l.pdf),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onDownloadDocx,
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
          child: Text(l.docx),
        ),
      ],
    );
  }
}
