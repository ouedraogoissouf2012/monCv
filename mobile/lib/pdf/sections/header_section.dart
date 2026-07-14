part of '../pdf_renderer.dart';

pw.Widget _sectionHeader(String title, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5, top: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
              width: 3,
              height: 12,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(1.5)),
              )),
          pw.SizedBox(width: 8),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
                height: 0.5,
                decoration: pw.BoxDecoration(
                  color: PdfColor(accent.red, accent.green, accent.blue, 0.3),
                )),
          ),
        ],
      ),
    );

// Date alignee a droite
pw.Widget _datePill(String text, PdfColor accent) => pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 7.5,
        color: accent,
        fontWeight: pw.FontWeight.bold,
      ),
    );

// Barre de competence visuelle

// Bullet dot
pw.Widget _dot(PdfColor accent) => pw.Container(
      width: 6,
      height: 6,
      margin: const pw.EdgeInsets.only(top: 2.5, right: 8),
      decoration: pw.BoxDecoration(
        color: accent,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
    );

// Experience item

class HeaderSection {
  const HeaderSection._();

  static pw.Widget build(String title, PdfColor accent) =>
      _sectionHeader(title, accent);
}
