import 'package:flutter/material.dart';

import '../cv_document_view_model.dart';
import '../sections/cv_body_sections.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « Classique » : en-tete blanc centre (nom + titre + contact) sous
/// une double barre d'accent, puis corps commun (issue #243). Extrait a
/// l'identique de `_ClassiqueTemplate`.
class ClassiquePreviewTemplate extends CvPreviewTemplate {
  const ClassiquePreviewTemplate();

  @override
  String get id => 'classique';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final cv = document.cv;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true) info!.ville!,
      ...?info?.sensitiveDisplayParts,
    ].join('   |   ');

    return DefaultTextStyle(
      style: CvDocumentTheme.font(
        cv.style.fontFamily,
        const TextStyle(
            fontSize: CvDocumentTheme.sizeBody,
            color: CvDocumentTheme.textBody),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
            if (info?.titrePoste?.isNotEmpty == true)
              Center(
                child: Text(info!.titrePoste!,
                    style: TextStyle(
                        fontSize: CvDocumentTheme.sizeName,
                        color: accent,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(contact,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeMeta,
                      color: CvDocumentTheme.textMuted)),
            ),
            const SizedBox(height: 10),
            Container(height: 2.5, color: accent),
            const SizedBox(height: 1),
            Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
            CvBodySections(document: document, accent: accent),
          ],
        ),
      ),
    );
  }
}
