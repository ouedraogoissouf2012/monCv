part of '../pdf_renderer.dart';

pw.Widget _skillsSection(List<Skill> skills, PdfColor accent) {
  // Verifier si les skills contiennent des categories (format "Categorie: skill1, skill2")
  final hasCategories = skills
      .any((s) => (s.nom ?? '').contains(':') || (s.nom ?? '').contains('|'));

  if (hasCategories) {
    return _skillsCategorized(skills, accent);
  }
  return _skillsSimple(skills, accent);
}

// Affichage categorise: "Backend: Java, Spring Boot"
pw.Widget _skillsCategorized(List<Skill> skills, PdfColor accent) {
  // Joindre tous les skills et parser les categories
  final allText = skills.map((s) => s.nom ?? '').join(', ');
  // Separer par | pour obtenir les categories
  final categories = allText
      .split('|')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: categories.map((cat) {
      // Format: "Categorie: skill1, skill2" ou juste "skill1, skill2"
      final parts = cat.split(':');
      if (parts.length >= 2) {
        final label = _sanitize(parts[0].trim());
        final items = _sanitize(parts.sublist(1).join(':').trim());
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: '$label : ',
                  style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: accent)),
              pw.TextSpan(
                  text: items,
                  style: const pw.TextStyle(
                      fontSize: 8.5, color: PdfColors.grey800)),
            ]),
          ),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(_sanitize(cat), style: _bodyStyle(size: 8.5)),
      );
    }).toList(),
  );
}

// Affichage simple avec barres de progression
pw.Widget _skillsSimple(List<Skill> skills, PdfColor accent) {
  final splitData = _splitSkillsWithLevel(skills);
  return pw.Column(
    children: splitData
        .map((s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(children: [
                pw.SizedBox(
                  width: 78,
                  child: pw.Text(_sanitize(s.name),
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      )),
                ),
                pw.Expanded(
                  child: pw.ClipRRect(
                    horizontalRadius: 1.5,
                    verticalRadius: 1.5,
                    child: pw.LinearProgressIndicator(
                      value: skillLevelProgress(s.niveau),
                      minHeight: 3,
                      backgroundColor: _progressTrackColor(accent),
                      valueColor: accent,
                    ),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.SizedBox(
                  width: 58,
                  child: pw.Text(
                    skillLevelLabel(s.niveau),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: accent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ]),
            ))
        .toList(),
  );
}

// Langues: nom + label descriptif + barre
pw.Widget _miniBar(
  int niveau,
  PdfColor filledColor,
  PdfColor emptyColor,
) {
  final filled = niveau.clamp(1, 5);
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: List.generate(5, (i) {
      return pw.Container(
        width: 8,
        height: 4,
        margin: const pw.EdgeInsets.only(right: 2),
        decoration: pw.BoxDecoration(
          color: i < filled ? filledColor : emptyColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
      );
    }),
  );
}

// ── TEMPLATE 1 : MODERNE ─────────────────────────────────────────────────────

class SkillsSection {
  const SkillsSection._();

  static pw.Widget build(List<Skill> skills, PdfColor accent) =>
      _skillsSection(skills, accent);
}
