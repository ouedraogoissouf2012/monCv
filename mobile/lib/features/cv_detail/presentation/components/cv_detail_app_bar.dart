import 'package:flutter/material.dart';

/// Barre d'actions de l'ecran de detail d'un CV (issue #247, B4b).
///
/// Extraite du monolithe. Toutes les actions remontent via callbacks pour
/// garder l'ecran mince ; les indicateurs de chargement des exports refletent
/// l'etat du [CvDetailController] fourni par l'ecran.
class CvDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CvDetailAppBar({
    super.key,
    required this.title,
    required this.exportingPdf,
    required this.exportingDocx,
    required this.onBack,
    required this.onProofread,
    required this.onEnhance,
    required this.onAdaptToJob,
    required this.onCustomize,
    required this.onExportPdf,
    required this.onExportDocx,
    required this.onEdit,
    required this.tooltips,
  });

  final String title;
  final bool exportingPdf;
  final bool exportingDocx;
  final VoidCallback onBack;
  final VoidCallback onProofread;
  final VoidCallback onEnhance;
  final VoidCallback onAdaptToJob;
  final VoidCallback onCustomize;
  final VoidCallback onExportPdf;
  final VoidCallback onExportDocx;
  final VoidCallback onEdit;

  /// Libelles localises (resolus par l'ecran).
  final CvDetailTooltips tooltips;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
            icon: const Icon(Icons.spellcheck_rounded),
            tooltip: tooltips.proofread,
            onPressed: onProofread),
        IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: tooltips.enhance,
            onPressed: onEnhance),
        IconButton(
            icon: const Icon(Icons.work_outline_rounded),
            tooltip: tooltips.adaptToJob,
            onPressed: onAdaptToJob),
        IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: tooltips.customize,
            onPressed: onCustomize),
        _ExportAction(
          busy: exportingPdf,
          icon: Icons.picture_as_pdf_outlined,
          tooltip: tooltips.downloadPdf,
          onPressed: onExportPdf,
        ),
        _ExportAction(
          busy: exportingDocx,
          icon: Icons.description_outlined,
          tooltip: tooltips.downloadDocx,
          onPressed: onExportDocx,
        ),
        IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: tooltips.edit,
            onPressed: onEdit),
      ],
    );
  }
}

/// Action d'export : spinner pendant le telechargement, icone sinon.
class _ExportAction extends StatelessWidget {
  const _ExportAction({
    required this.busy,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool busy;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
        icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
  }
}

/// Regroupe les libelles localises des actions (resolus par l'ecran, le
/// composant reste localise-agnostique).
class CvDetailTooltips {
  const CvDetailTooltips({
    required this.proofread,
    required this.enhance,
    required this.adaptToJob,
    required this.customize,
    required this.downloadPdf,
    required this.downloadDocx,
    required this.edit,
  });

  final String proofread;
  final String enhance;
  final String adaptToJob;
  final String customize;
  final String downloadPdf;
  final String downloadDocx;
  final String edit;
}
