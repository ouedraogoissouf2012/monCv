import 'cv_preview_template.dart';

/// Registre des templates de preview CV (issue #243).
///
/// Resout un [CvPreviewTemplate] a partir de `cv.style.templateId`, avec repli
/// deterministe sur un template par defaut si l'identifiant est inconnu.
/// Remplace le `switch` monolithique de `cv_preview.dart` : ajouter un template
/// = l'enregistrer ici, sans toucher aux autres (critere #243).
class CvPreviewTemplateRegistry {
  CvPreviewTemplateRegistry({
    required CvPreviewTemplate fallback,
    Iterable<CvPreviewTemplate> templates = const [],
  }) : _fallback = fallback {
    register(fallback);
    templates.forEach(register);
  }

  final CvPreviewTemplate _fallback;
  final Map<String, CvPreviewTemplate> _byId = {};

  /// Enregistre (ou remplace) un template par son [CvPreviewTemplate.id].
  void register(CvPreviewTemplate template) {
    _byId[template.id] = template;
  }

  /// Template par defaut (utilise quand l'id est inconnu).
  CvPreviewTemplate get fallback => _fallback;

  /// Tous les identifiants enregistres.
  Iterable<String> get ids => _byId.keys;

  /// Resout le template pour [templateId], ou le [fallback] si absent/null.
  CvPreviewTemplate resolve(String? templateId) =>
      _byId[templateId] ?? _fallback;
}
