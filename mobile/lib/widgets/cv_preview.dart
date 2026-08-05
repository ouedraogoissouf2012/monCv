import 'package:flutter/material.dart';

import '../features/cv_preview/domain/cv_document_view_model.dart';
import '../features/cv_preview/presentation/template/default_template_registry.dart';
import '../features/cv_preview/presentation/template/template_registry.dart';
import '../models/cv.dart';

/// Apercu d'un CV : selectionne le template via le registre (Strategy) et le
/// rend dans le cadre document commun (issue #243).
///
/// Ex-god widget de 1018 lignes : le dispatch par `switch`, les 6 templates,
/// les sections et les helpers ont ete extraits vers
/// `features/cv_preview/` (view model pur, theme document, sections partagees,
/// un fichier par template + registre). Cet orchestrateur ne fait plus que
/// resoudre la strategie et l'afficher.
class CvPreviewWidget extends StatelessWidget {
  const CvPreviewWidget({super.key, required this.cv});

  final Cv cv;

  /// Registre partage des 6 templates (construit une seule fois).
  static final CvPreviewTemplateRegistry _registry =
      buildDefaultPreviewRegistry();

  @override
  Widget build(BuildContext context) {
    final template = _registry.resolve(cv.style.templateId);
    final document = CvDocumentViewModel(cv);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          // Le CV est un DOCUMENT : son "papier" reste toujours blanc, quel que
          // soit le theme de l'application. Sans cela, en theme sombre (Premium),
          // le Material heritait de `cardColor` fonce et le texte du document
          // (couleurs fixes foncees de CvDocumentTheme) devenait illisible.
          child: Material(
            color: Colors.white,
            elevation: 6,
            borderRadius: BorderRadius.circular(4),
            child: template.build(context, document),
          ),
        ),
      ),
    );
  }
}
