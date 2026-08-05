import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../cv_list_controller.dart';

/// Traduit un code d'erreur d'import ([CvImportError.name] ou message backend)
/// en libelle localise (issue #249, D4).
String importErrorMessage(AppLocalizations l, String? code) => switch (code) {
      'invalidExtension' => l.importInvalidExtension,
      'invalidContent' => l.importInvalidContent,
      'empty' => l.importEmptyFile,
      'tooLarge' => l.importTooLarge,
      _ => l.importError(code ?? ''),
    };

/// Bouton d'import de la barre d'actions : spinner pendant l'import (issue
/// #249, D4). Reflete [CvListController.importing].
class CvImportButton extends StatelessWidget {
  const CvImportButton({super.key, required this.controller, required this.onImport});

  final CvListController controller;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => IconButton(
        icon: controller.importing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file),
        tooltip: l.importCv,
        onPressed: controller.importing ? null : onImport,
      ),
    );
  }
}

/// Bouton "nouveau CV" (barre desktop). Route vers la creation.
class CvNewButton extends StatelessWidget {
  const CvNewButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: FilledButton.icon(
          onPressed: () => context.push('/cvs/create'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(AppLocalizations.of(context)!.newCv),
        ),
      );
}

/// FAB "nouveau CV" (mobile).
class CvNewFab extends StatelessWidget {
  const CvNewFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        onPressed: () => context.push('/cvs/create'),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newCv),
      );
}
