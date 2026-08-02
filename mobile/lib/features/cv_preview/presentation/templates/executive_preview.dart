import 'package:flutter/material.dart';

import '../../domain/cv_document_view_model.dart';
import '../sections/cv_body_sections.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « Executive » : nom a gauche, contact aligne a droite, barre epaisse
/// d'accent, puis corps commun (issue #243). Extrait a l'identique de
/// `_ExecutiveTemplate`.
class ExecutivePreviewTemplate extends CvPreviewTemplate {
  const ExecutivePreviewTemplate();

  @override
  String get id => 'executive';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final cv = document.cv;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    const contactStyle = TextStyle(
        fontSize: CvDocumentTheme.sizeMeta, color: CvDocumentTheme.textMuted);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      if (info?.titrePoste?.isNotEmpty == true)
                        Text(info!.titrePoste!,
                            style: TextStyle(
                                fontSize: CvDocumentTheme.sizeName,
                                color: accent,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (info?.email?.isNotEmpty == true)
                      Text(info!.email!, style: contactStyle),
                    if (info?.telephone?.isNotEmpty == true)
                      Text(info!.telephone!, style: contactStyle),
                    if (info?.ville?.isNotEmpty == true)
                      Text(
                          '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
                          style: contactStyle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 3, color: accent),
            const SizedBox(height: 1),
            Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
            CvBodySections(document: document, accent: accent),
          ],
        ),
      ),
    );
  }
}
