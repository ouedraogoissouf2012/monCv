part of '../pdf_renderer.dart';

List<pw.Widget> _buildDescriptionLines(String desc, PdfColor accent) {
  final lines = desc.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length <= 1 && !desc.contains('- ')) {
    // Texte simple sans tirets
    return [pw.Text(desc, style: _bodyStyle(size: 9))];
  }
  return lines.map((line) {
    final trimmed = line.trim();
    final isBullet = trimmed.startsWith('- ') || trimmed.startsWith('* ');
    final text = isBullet ? trimmed.substring(2) : trimmed;
    if (isBullet) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3, left: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(top: 3, right: 6),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.Expanded(
              child: pw.Text(text, style: _bodyStyle(size: 9)),
            ),
          ],
        ),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: _bodyStyle(size: 9)),
    );
  }).toList();
}

// Education item with dot + content + date pill

class SummarySection {
  const SummarySection._();

  static List<pw.Widget> build(String text, PdfColor accent) =>
      _buildDescriptionLines(text, accent);
}
