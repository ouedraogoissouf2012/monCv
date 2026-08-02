import 'package:flutter/material.dart';

import '../../domain/cv_document_view_model.dart';
import '../sections/cv_body_sections.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « Minimaliste » : nom grand aligne a gauche, contact discret, filet
/// fin, puis corps commun (issue #243). Extrait a l'identique de
/// `_MinimalisteTemplate`.
class MinimalistePreviewTemplate extends CvPreviewTemplate {
  const MinimalistePreviewTemplate();

  @override
  String get id => 'minimaliste';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final cv = document.cv;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true) info!.ville!,
    ].join('   |   ');

    return DefaultTextStyle(
      style: CvDocumentTheme.font(
        cv.style.fontFamily,
        const TextStyle(
            fontSize: CvDocumentTheme.sizeBody,
            color: CvDocumentTheme.textBody),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800)),
            if (info?.titrePoste?.isNotEmpty == true)
              Text(info!.titrePoste!,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeName,
                      color: CvDocumentTheme.textFaint)),
            const SizedBox(height: 8),
            Text(contact,
                style: const TextStyle(
                    fontSize: CvDocumentTheme.sizeMeta,
                    color: CvDocumentTheme.textFaint)),
            const SizedBox(height: 14),
            Container(height: 0.8, color: CvDocumentTheme.divider),
            CvBodySections(document: document, accent: accent),
          ],
        ),
      ),
    );
  }
}
