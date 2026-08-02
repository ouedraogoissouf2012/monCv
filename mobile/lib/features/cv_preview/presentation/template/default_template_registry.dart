import 'templates_barrel.dart';
import 'cv_preview_template.dart';
import 'template_registry.dart';

/// Construit le registre des templates de preview avec les 6 strategies du
/// produit (issue #243).
///
/// Point unique d'enregistrement : ajouter un template = l'ajouter ici (et
/// ecrire son implementation + ses tests), sans modifier `CvPreviewWidget` ni
/// les autres templates. Le fallback est Moderne (comportement historique du
/// `switch` du monolithe : `default -> moderne`).
CvPreviewTemplateRegistry buildDefaultPreviewRegistry() =>
    CvPreviewTemplateRegistry(
      fallback: const ModernePreviewTemplate(),
      templates: const <CvPreviewTemplate>[
        ClassiquePreviewTemplate(),
        MinimalistePreviewTemplate(),
        CreatifPreviewTemplate(),
        ExecutivePreviewTemplate(),
        AtsPreviewTemplate(),
      ],
    );
