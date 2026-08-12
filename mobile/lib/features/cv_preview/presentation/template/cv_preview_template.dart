import 'package:flutter/widgets.dart';

import '../cv_document_view_model.dart';

/// Contrat d'un template de preview CV (issue #243).
///
/// Strategy : chaque style de CV (moderne, classique, ATS...) est une
/// implementation distincte. Calque sur `PdfTemplate` cote PDF (deja en place),
/// pour aligner preview et PDF sur le meme decoupage. Le template recoit un
/// [CvDocumentViewModel] (vue metier pure), jamais le modele brut.
abstract class CvPreviewTemplate {
  const CvPreviewTemplate();

  /// Identifiant stable du template (doit correspondre a `cv.style.templateId`).
  String get id;

  /// Construit le rendu Flutter du CV pour ce template.
  Widget build(BuildContext context, CvDocumentViewModel document);
}
