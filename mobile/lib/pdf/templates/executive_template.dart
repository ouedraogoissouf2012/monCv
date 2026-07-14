part of '../pdf_renderer.dart';

pw.Document _buildExecutive(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
    build: (ctx) => [
      // Header: nom gauche, contact droite
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(
              '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black),
            ),
            if (info?.titrePoste?.isNotEmpty == true)
              pw.Text(info!.titrePoste!,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            if (info?.email?.isNotEmpty == true)
              pw.Text(info!.email!, style: _bodyStyle(size: 8.5)),
            if (info?.telephone?.isNotEmpty == true)
              pw.Text(info!.telephone!, style: _bodyStyle(size: 8.5)),
            if (info?.ville?.isNotEmpty == true)
              pw.Text(
                  '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
                  style: _bodyStyle(size: 8.5)),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 3, decoration: pw.BoxDecoration(color: accent)),
      pw.SizedBox(height: 1),
      pw.Container(
          height: 0.5,
          decoration: pw.BoxDecoration(
              color: PdfColor(accent.red, accent.green, accent.blue, 0.3))),
      pw.SizedBox(height: 16),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        pw.Text(
          info!.resumeProfessionnel!,
          style: _bodyStyle(size: 9.5, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
            height: 0.5,
            decoration: const pw.BoxDecoration(color: PdfColors.grey300)),
        pw.SizedBox(height: 12),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences professionnelles', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 6),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 6),
      ],
      if (cv.skills.isNotEmpty || cv.languages.isNotEmpty) ...[
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
                    ]),
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
                    ]),
              ),
          ],
        ),
      ],
      if (cv.certifications.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionHeader('Certifications', accent),
        ...cv.certifications.map((c) => _certItem(c, accent)),
      ],
      if (cv.projects.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _sectionHeader('Projets', accent),
        ...cv.projects.map((p) => _projectItem(p, accent)),
      ],
    ],
  ));
  return doc;
}

// ── TEMPLATE 6 : ATS-SAFE ───────────────────────────────────────────────────
// 100% compatible ATS : 1 colonne, pas de graphiques, pas de photo,
// pas de barres, pas de couleur, texte pur.

class ExecutivePdfTemplate implements PdfTemplate {
  const ExecutivePdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) =>
      _buildExecutive(cv, theme.accent, photo: theme.photo);
}
