part of '../pdf_renderer.dart';

pw.Document _buildModerne(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) {
  final doc = pw.Document();
  final info = cv.personalInfo;
  final contactItems = <String>[
    if (info?.email?.isNotEmpty == true) info!.email!,
    if (info?.telephone?.isNotEmpty == true) info!.telephone!,
    if (info?.ville?.isNotEmpty == true)
      '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
    if (info?.linkedIn?.isNotEmpty == true) _sanitize(info!.linkedIn!),
    if (info?.portfolio?.isNotEmpty == true) _sanitize(info!.portfolio!),
  ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (ctx) => [
      // ── HEADER ──
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 24),
        decoration: pw.BoxDecoration(color: accent),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (photo != null) ...[
              pw.ClipOval(
                child: pw.Image(photo,
                    width: 60, height: 60, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Text(
              _sanitize('${info?.prenom ?? ''} ${info?.nom ?? ''}')
                  .trim()
                  .toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 4,
              ),
            ),
            if (info?.titrePoste?.isNotEmpty == true) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                _sanitize(info!.titrePoste!),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                  fontStyle: pw.FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Container(
                height: 0.4,
                width: 250,
                decoration: const pw.BoxDecoration(
                  color: PdfColor(1, 1, 1, 0.4),
                )),
            pw.SizedBox(height: 10),
            pw.Text(
              contactItems.map(_sanitize).join('   |   '),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
            ),
          ],
        ),
      ),

      // ── BODY ──
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(40, 16, 40, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. Resume
            if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
              _sectionHeader('Profil', accent),
              pw.Text(_sanitize(info!.resumeProfessionnel!),
                  style: _bodyStyle(size: 8.5)),
            ],

            // 2. Competences + Langues (cote a cote, AVANT les experiences)
            if (cv.skills.isNotEmpty || cv.languages.isNotEmpty)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty)
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Compétences', accent),
                          _skillsSection(cv.skills, accent),
                        ],
                      ),
                    ),
                  if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
                    pw.SizedBox(width: 24),
                  if (cv.languages.isNotEmpty)
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Langues', accent),
                          _languagesSection(cv.languages, accent),
                        ],
                      ),
                    ),
                ],
              ),

            // 3. Experiences
            if (cv.experiences.isNotEmpty) ...[
              _sectionHeader('Expériences professionnelles', accent),
              ...cv.experiences.map((e) => _experienceItem(e, accent)),
            ],

            // 4. Formations
            if (cv.educations.isNotEmpty) ...[
              _sectionHeader('Formations', accent),
              ...cv.educations.map((e) => _educationItem(e, accent)),
            ],

            // 5. Certifications + Projets cote a cote
            if (cv.certifications.isNotEmpty || cv.projects.isNotEmpty)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (cv.certifications.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Certifications', accent),
                          ...cv.certifications.map((c) => _certItem(c, accent)),
                        ],
                      ),
                    ),
                  if (cv.certifications.isNotEmpty && cv.projects.isNotEmpty)
                    pw.SizedBox(width: 24),
                  if (cv.projects.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Projets', accent),
                          ...cv.projects.map((p) => _projectItem(p, accent)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ],
  ));

  return doc;
}

// ── TEMPLATE 2 : CLASSIQUE ───────────────────────────────────────────────────

class ModernePdfTemplate implements PdfTemplate {
  const ModernePdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) =>
      _buildModerne(cv, theme.accent, photo: theme.photo);
}
