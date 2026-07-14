part of '../pdf_renderer.dart';

pw.Widget _languagesSection(List<Language> langs, PdfColor accent) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: langs.map((l) {
        final label = languageLevelDisplay(l.niveau);
        final level = languageLevelProgress(l.niveau);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_sanitize(l.langue ?? ''),
                      style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900)),
                  pw.Text(label,
                      style: pw.TextStyle(
                          fontSize: 7.5,
                          color: accent,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.ClipRRect(
                horizontalRadius: 1.5,
                verticalRadius: 1.5,
                child: pw.LinearProgressIndicator(
                  value: level,
                  minHeight: 3,
                  backgroundColor: _progressTrackColor(accent),
                  valueColor: accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

class LanguagesSection {
  const LanguagesSection._();

  static pw.Widget build(List<Language> languages, PdfColor accent) =>
      _languagesSection(languages, accent);
}
