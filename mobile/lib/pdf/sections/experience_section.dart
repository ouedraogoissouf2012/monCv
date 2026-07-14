part of '../pdf_renderer.dart';

pw.Widget _experienceItem(Experience e, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Ligne 1: Poste + Date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitize(e.poste ?? ''),
                  style: _boldStyle(size: 10),
                ),
              ),
              pw.SizedBox(width: 8),
              _datePill(
                  _dateRange(e.dateDebut, e.dateFin, actuel: e.actuel), accent),
            ],
          ),
          // Ligne 2: Entreprise + Lieu
          if (e.entreprise?.isNotEmpty == true ||
              e.lieu?.isNotEmpty == true) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _sanitize([
                if (e.entreprise?.isNotEmpty == true) e.entreprise!,
                if (e.lieu?.isNotEmpty == true) e.lieu!,
              ].join(' - ')),
              style: _bodyStyle(size: 8.5, color: PdfColors.grey600),
            ),
          ],
          // Description: chaque ligne commencant par - est un bullet
          if (e.description?.isNotEmpty == true) ...[
            pw.SizedBox(height: 5),
            ..._buildDescriptionLines(_sanitize(e.description!), accent),
          ],
        ],
      ),
    );

// Transforme une description en lignes formatees

class ExperienceSection {
  const ExperienceSection._();

  static pw.Widget build(Experience experience, PdfColor accent) =>
      _experienceItem(experience, accent);
}
