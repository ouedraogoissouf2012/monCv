part of '../pdf_renderer.dart';

pw.Document _buildAts(Cv cv, PdfColor accent) {
  final doc = pw.Document();
  final info = cv.personalInfo;
  // Keep these runtime values to preserve the original widget construction.
  // ignore: prefer_const_declarations
  final black = PdfColors.black;
  // ignore: prefer_const_declarations
  final grey = PdfColors.grey700;
  final splitSkills = _splitSkillsWithLevel(cv.skills);

  pw.Widget atsSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: black,
                  letterSpacing: 1,
                )),
            pw.Container(
                height: 0.8, decoration: pw.BoxDecoration(color: black)),
          ],
        ),
      );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
    build: (ctx) => [
      pw.Text(
        _sanitize('${info?.prenom ?? ''} ${info?.nom ?? ''}').trim(),
        style: pw.TextStyle(
            fontSize: 22, fontWeight: pw.FontWeight.bold, color: black),
      ),
      if (info?.titrePoste?.isNotEmpty == true)
        pw.Text(_sanitize(info!.titrePoste!),
            style: pw.TextStyle(
                fontSize: 12, color: grey, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text(
        [
          if (info?.email?.isNotEmpty == true) _sanitize(info!.email!),
          if (info?.telephone?.isNotEmpty == true) _sanitize(info!.telephone!),
          if (info?.ville?.isNotEmpty == true)
            _sanitize(
                '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}'),
          if (info?.linkedIn?.isNotEmpty == true) _sanitize(info!.linkedIn!),
          if (info?.portfolio?.isNotEmpty == true) _sanitize(info!.portfolio!),
        ].join('  |  '),
        style: pw.TextStyle(fontSize: 9, color: grey),
      ),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        atsSection('Profil'),
        pw.Text(_sanitize(info!.resumeProfessionnel!),
            style: pw.TextStyle(fontSize: 10, color: black, lineSpacing: 1.3)),
      ],
      if (splitSkills.isNotEmpty) ...[
        atsSection('Compétences'),
        pw.Text(
          splitSkills
              .map((skill) =>
                  '${_sanitize(skill.name)} (${skillLevelLabel(skill.niveau)})')
              .join('  -  '),
          style: pw.TextStyle(fontSize: 10, color: black),
        ),
      ],
      if (cv.languages.isNotEmpty) ...[
        atsSection('Langues'),
        pw.Text(
          cv.languages
              .map((l) =>
                  '${_sanitize(l.langue ?? '')} (${languageLevelDisplay(l.niveau)})')
              .join('  -  '),
          style: pw.TextStyle(fontSize: 10, color: black),
        ),
      ],
      if (cv.experiences.isNotEmpty) ...[
        atsSection('Experience professionnelle'),
        ...cv.experiences.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(_sanitize(e.poste ?? ''),
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: black)),
                          pw.Text(
                              _dateRange(e.dateDebut, e.dateFin,
                                  actuel: e.actuel),
                              style: pw.TextStyle(fontSize: 9, color: grey)),
                        ]),
                    pw.Text(
                        _sanitize([e.entreprise, e.lieu]
                            .where((s) => s?.isNotEmpty == true)
                            .join(', ')),
                        style: pw.TextStyle(fontSize: 9, color: grey)),
                    if (e.description?.isNotEmpty == true) ...[
                      pw.SizedBox(height: 3),
                      ..._buildDescriptionLines(
                          _sanitize(e.description!), accent),
                    ],
                  ]),
            )),
      ],
      if (cv.educations.isNotEmpty) ...[
        atsSection('Formation'),
        ...cv.educations.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e.diplome ?? '',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: black)),
                          pw.Text(_dateRange(e.dateDebut, e.dateFin),
                              style: pw.TextStyle(fontSize: 9, color: grey)),
                        ]),
                    if (e.etablissement?.isNotEmpty == true)
                      pw.Text(_sanitize(e.etablissement!),
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                  ]),
            )),
      ],
      if (cv.certifications.isNotEmpty) ...[
        atsSection('Certifications'),
        ...cv.certifications.map((c) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(_sanitize(c.nom ?? ''),
                    style: pw.TextStyle(fontSize: 10, color: black)),
                pw.Text(_fmtDate(c.dateObtention),
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              ],
            )),
      ],
    ],
  ));
  return doc;
}

class AtsPdfTemplate implements PdfTemplate {
  const AtsPdfTemplate();

  @override
  pw.Document build(Cv cv, PdfTheme theme) => _buildAts(cv, theme.accent);
}
