part of '../pdf_renderer.dart';

abstract class PdfTemplate {
  const PdfTemplate();

  pw.Document build(Cv cv, PdfTheme theme);
}
