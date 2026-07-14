part of '../pdf_renderer.dart';

pw.Document _buildClassique(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    build: (ctx) => [
      // En-tête centré avec accent
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black),
            ),
            if (info?.titrePoste?.isNotEmpty == true) ...[
              pw.SizedBox(height: 4),
              pw.Text(info!.titrePoste!,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              [
                if (info?.email?.isNotEmpty == true) info!.email!,
                if (info?.telephone?.isNotEmpty == true) info!.telephone!,
                if (info?.ville?.isNotEmpty == true) info!.ville!,
                if (info?.linkedIn?.isNotEmpty == true) info!.linkedIn!,
                if (info?.portfolio?.isNotEmpty == true) info!.portfolio!,
              ].join('   |   '),
              style: _bodyStyle(size: 8.5, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(height: 2, decoration: pw.BoxDecoration(color: accent)),
      pw.SizedBox(height: 2),
      pw.Container(
          height: 0.5,
          decoration: pw.BoxDecoration(
              color: PdfColor(accent.red, accent.green, accent.blue, 0.3))),
      pw.SizedBox(height: 16),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        _sectionHeader('Résumé professionnel', accent),
        pw.Text(_sanitize(info!.resumeProfessionnel!),
            style: _bodyStyle(size: 9.5)),
        pw.SizedBox(height: 12),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences professionnelles', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 4),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 4),
      ],
      if (cv.skills.isNotEmpty) ...[
        _sectionHeader('Compétences', accent),
        pw.SizedBox(height: 4),
        _skillsSection(cv.skills, accent),
        pw.SizedBox(height: 10),
      ],
      if (cv.languages.isNotEmpty) ...[
        _sectionHeader('Langues', accent),
        pw.SizedBox(height: 4),
        _languagesSection(cv.languages, accent),
        pw.SizedBox(height: 10),
      ],
    ],
  ));
  return doc;
}

// ── TEMPLATE 3 : MINIMALISTE ─────────────────────────────────────────────────

class ClassiquePdfTemplate implements PdfTemplate {
  const ClassiquePdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) =>
      _buildClassique(cv, theme.accent, photo: theme.photo);
}
