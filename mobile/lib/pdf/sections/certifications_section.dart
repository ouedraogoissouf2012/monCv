part of '../pdf_renderer.dart';

pw.Widget _certItem(Certification c, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _dot(accent),
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(c.nom ?? '', style: _boldStyle(size: 9)),
                      if (c.organisme?.isNotEmpty == true)
                        pw.Text(c.organisme!,
                            style:
                                _bodyStyle(size: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                if (c.dateObtention != null)
                  _datePill(_fmtDate(c.dateObtention), accent),
              ],
            ),
          ),
        ],
      ),
    );

class CertificationsSection {
  const CertificationsSection._();

  static pw.Widget build(Certification certification, PdfColor accent) =>
      _certItem(certification, accent);
}
