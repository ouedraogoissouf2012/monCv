part of '../pdf_renderer.dart';

pw.Widget _educationItem(Education e, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _dot(accent),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        e.diplome ?? '',
                        style: _boldStyle(size: 9.5),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    _datePill(_dateRange(e.dateDebut, e.dateFin), accent),
                  ],
                ),
                if (e.etablissement?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    e.etablissement!,
                    style: _bodyStyle(size: 8.5, color: PdfColors.grey600),
                  ),
                ],
                if (e.domaine?.isNotEmpty == true)
                  pw.Text(e.domaine!,
                      style: _bodyStyle(size: 8, color: PdfColors.grey500)),
                if (e.description?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(_sanitize(e.description!),
                      style: _bodyStyle(size: 9)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

// Skills: detecte si l'IA a retourne des categories (Backend: X, Y | Frontend: Z)
// et les affiche proprement

class EducationSection {
  const EducationSection._();

  static pw.Widget build(Education education, PdfColor accent) =>
      _educationItem(education, accent);
}
