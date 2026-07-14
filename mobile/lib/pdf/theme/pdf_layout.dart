part of '../pdf_renderer.dart';

class PdfTheme {
  const PdfTheme({required this.accent, this.photo});

  final PdfColor accent;
  final pw.MemoryImage? photo;
}

class PdfLayout {
  const PdfLayout._();

  static const pageFormat = PdfPageFormat.a4;
  static const sectionSpacing = 10.0;
}
