part of '../pdf_renderer.dart';

pw.TextStyle _bodyStyle(
        {double size = 8.5, PdfColor? color, double height = 1.35}) =>
    pw.TextStyle(
      fontSize: size,
      color: color ?? PdfColors.grey800,
      lineSpacing: height,
    );

pw.TextStyle _boldStyle({double size = 9.5, PdfColor? color}) => pw.TextStyle(
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColor.fromHex('#1a1a1a'),
    );
