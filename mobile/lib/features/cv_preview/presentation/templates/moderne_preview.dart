import 'package:flutter/material.dart';

import '../../../../widgets/secure_photo.dart';
import '../cv_document_view_model.dart';
import '../sections/cv_body_sections.dart';
import '../template/cv_preview_template.dart';
import '../theme/cv_document_theme.dart';

/// Template « Moderne » : bandeau colore centre (photo + nom + titre + contact)
/// puis corps commun (issue #243). Extrait a l'identique de `_ModerneTemplate`.
class ModernePreviewTemplate extends CvPreviewTemplate {
  const ModernePreviewTemplate();

  @override
  String get id => 'moderne';

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) {
    final cv = document.cv;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true)
        '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
    ].join('   |   ');

    return DefaultTextStyle(
      style: CvDocumentTheme.font(
        cv.style.fontFamily,
        const TextStyle(
            fontSize: CvDocumentTheme.sizeBody,
            color: CvDocumentTheme.textBody),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 22),
            decoration: BoxDecoration(
              color: accent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Column(children: [
              if (info?.photoUrl?.isNotEmpty == true) ...[
                ClipOval(
                  child: SecurePhoto(
                    url: info!.photoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    fallback: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(Icons.person,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim().toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3),
              ),
              if (info?.titrePoste?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(info!.titrePoste!,
                    style: TextStyle(
                        fontSize: CvDocumentTheme.sizeName,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 12),
              Container(
                  height: 0.4,
                  width: 200,
                  color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text(contact,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: CvDocumentTheme.sizeMeta, color: Colors.white)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
            child: CvBodySections(document: document, accent: accent),
          ),
        ],
      ),
    );
  }
}
