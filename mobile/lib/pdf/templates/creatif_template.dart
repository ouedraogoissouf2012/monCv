part of '../pdf_renderer.dart';

pw.Document _buildCreatif(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) {
  final doc = pw.Document();
  final info = cv.personalInfo;
  const sidebarWidth = 185.0;
  final splitSkills = _splitSkillsWithLevel(cv.skills);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (ctx) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Sidebar ──
        pw.Container(
          width: sidebarWidth,
          decoration: pw.BoxDecoration(color: accent),
          padding: const pw.EdgeInsets.fromLTRB(18, 28, 18, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Photo
              if (photo != null) ...[
                pw.Center(
                    child: pw.ClipOval(
                  child: pw.Image(photo,
                      width: 55, height: 55, fit: pw.BoxFit.cover),
                )),
                pw.SizedBox(height: 10),
              ],
              // Nom
              pw.Text(
                _sanitize('${info?.prenom ?? ''}\n${info?.nom ?? ''}'.trim()),
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    lineSpacing: 2),
              ),
              if (info?.titrePoste?.isNotEmpty == true) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                    height: 0.4,
                    decoration: const pw.BoxDecoration(color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Text(_sanitize(info!.titrePoste!),
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontStyle: pw.FontStyle.italic)),
              ],
              // Contact
              pw.SizedBox(height: 20),
              _sideSection('CONTACT'),
              if (info?.email?.isNotEmpty == true)
                _sideItem(_sanitize(info!.email!)),
              if (info?.telephone?.isNotEmpty == true)
                _sideItem(_sanitize(info!.telephone!)),
              if (info?.ville?.isNotEmpty == true)
                _sideItem(_sanitize(info!.ville!)),
              // Competences separees avec barres
              if (splitSkills.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('COMPÉTENCES'),
                ...splitSkills.take(10).map((skill) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  _sanitize(skill.name),
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                              pw.Text(
                                skillLevelLabel(skill.niveau),
                                style: pw.TextStyle(
                                  fontSize: 6.2,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          _miniBar(
                            skill.niveau,
                            PdfColors.white,
                            _mixPdfColors(accent, PdfColors.white, 0.30),
                          ),
                        ],
                      ),
                    )),
              ],
              // Langues
              if (cv.languages.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('LANGUES'),
                ...cv.languages.map((l) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(_sanitize(l.langue ?? ''),
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.white)),
                          pw.Text(languageLevelLabel(l.niveau),
                              style: pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
              // Certifications
              if (cv.certifications.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('CERTIFICATIONS'),
                ...cv.certifications.map((c) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(_sanitize(c.nom ?? ''),
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.white)),
                    )),
              ],
            ],
          ),
        ),
        // Contenu principal
        pw.Expanded(
          child: pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
                  _sectionHeader('Résumé', accent),
                  pw.Text(_sanitize(info!.resumeProfessionnel!),
                      style: _bodyStyle(size: 9)),
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
                if (cv.certifications.isNotEmpty) ...[
                  _sectionHeader('Certifications', accent),
                  ...cv.certifications.map((c) => _certItem(c, accent)),
                ],
                if (cv.projects.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _sectionHeader('Projets', accent),
                  ...cv.projects.map((p) => _projectItem(p, accent)),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  ));
  return doc;
}

class CreatifPdfTemplate implements PdfTemplate {
  const CreatifPdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) =>
      _buildCreatif(cv, theme.accent, photo: theme.photo);
}
