part of '../pdf_renderer.dart';

PdfColor _mixPdfColors(PdfColor from, PdfColor to, double amount) {
  final ratio = amount.clamp(0.0, 1.0).toDouble();
  return PdfColor(
    from.red + (to.red - from.red) * ratio,
    from.green + (to.green - from.green) * ratio,
    from.blue + (to.blue - from.blue) * ratio,
  );
}

PdfColor _progressTrackColor(PdfColor accent) =>
    _mixPdfColors(PdfColors.white, accent, 0.12);

// Section header: colored left bar + title + fine line
