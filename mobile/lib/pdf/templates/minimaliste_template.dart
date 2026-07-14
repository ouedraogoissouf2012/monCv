part of '../pdf_renderer.dart';

pw.Document _buildMinimaliste(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 52, vertical: 44),
    build: (ctx) => [
      pw.Text(
        '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
        style: pw.TextStyle(
            fontSize: 30,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black),
      ),
      if (info?.titrePoste?.isNotEmpty == true) ...[
        pw.SizedBox(height: 2),
        pw.Text(info!.titrePoste!,
            style: _bodyStyle(size: 11, color: PdfColors.grey600)),
      ],
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          if (info?.email?.isNotEmpty == true)
            pw.Text(info!.email!,
                style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          if (info?.telephone?.isNotEmpty == true) ...[
            pw.Text('   |   ',
                style: _bodyStyle(size: 8.5, color: PdfColors.grey400)),
            pw.Text(info!.telephone!,
                style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          ],
          if (info?.ville?.isNotEmpty == true) ...[
            pw.Text('   |   ',
                style: _bodyStyle(size: 8.5, color: PdfColors.grey400)),
            pw.Text(info!.ville!,
                style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          ],
        ],
      ),
      pw.SizedBox(height: 20),
      pw.Container(
          height: 0.8,
          decoration: const pw.BoxDecoration(color: PdfColors.grey300)),
      pw.SizedBox(height: 20),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        pw.Text(_sanitize(info!.resumeProfessionnel!),
            style: _bodyStyle(size: 9.5)),
        pw.SizedBox(height: 16),
        pw.Container(
            height: 0.5,
            decoration: const pw.BoxDecoration(color: PdfColors.grey200)),
        pw.SizedBox(height: 16),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences professionnelles', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 8),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 8),
      ],
      if (cv.skills.isNotEmpty) ...[
        _sectionHeader('Compétences', accent),
        pw.SizedBox(height: 4),
        _skillsSection(cv.skills, accent),
        pw.SizedBox(height: 12),
      ],
      if (cv.languages.isNotEmpty) ...[
        _sectionHeader('Langues', accent),
        pw.SizedBox(height: 4),
        _languagesSection(cv.languages, accent),
      ],
    ],
  ));
  return doc;
}

// ── TEMPLATE 4 : CRÉATIF (sidebar) ───────────────────────────────────────────

class MinimalistePdfTemplate implements PdfTemplate {
  const MinimalistePdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) =>
      _buildMinimaliste(cv, theme.accent, photo: theme.photo);
}
