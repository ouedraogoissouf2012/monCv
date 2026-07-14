part of '../pdf_renderer.dart';

pw.Widget _sideSection(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 1.2),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
              height: 0.5,
              decoration: const pw.BoxDecoration(color: PdfColors.white)),
        ],
      ),
    );

pw.Widget _sideItem(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
    );

// ── TEMPLATE 5 : EXECUTIVE ───────────────────────────────────────────────────
