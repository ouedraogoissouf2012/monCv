part of '../pdf_renderer.dart';

pw.Widget _projectItem(Project p, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _dot(accent),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(p.nom ?? '', style: _boldStyle(size: 9.5)),
                if (p.technologies?.isNotEmpty == true)
                  pw.Text(_sanitize(p.technologies!),
                      style: _bodyStyle(size: 8, color: PdfColors.grey600)),
                if (p.description?.isNotEmpty == true)
                  pw.Text(_sanitize(p.description!),
                      style: _bodyStyle(size: 9)),
              ],
            ),
          ),
        ],
      ),
    );

// Sidebar mini bar for Créatif template

class ProjectsSection {
  const ProjectsSection._();

  static pw.Widget build(Project project, PdfColor accent) =>
      _projectItem(project, accent);
}
