part of '../pdf_renderer.dart';

String _fmtDate(DateTime? d) {
  if (d == null) return '';
  return '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _dateRange(DateTime? debut, DateTime? fin, {bool actuel = false}) {
  final d = _fmtDate(debut);
  if (actuel || fin == null && debut != null) {
    return d.isEmpty ? 'En cours' : '$d - En cours';
  }
  final f = _fmtDate(fin);
  if (d.isEmpty && f.isEmpty) return '';
  if (f.isEmpty) return d;
  // Si meme mois/annee, afficher une seule fois
  if (d == f) return d;
  // Si meme annee, afficher seulement les annees
  if (debut?.year == fin?.year) return '${debut!.year}';
  return '$d - $f';
}

// Separe les competences en bloc en competences individuelles avec niveau
class _SkillData {
  final String name;
  final int niveau;
  _SkillData(this.name, this.niveau);
}

List<_SkillData> _splitSkillsWithLevel(List<Skill> skills) {
  final result = <_SkillData>[];
  for (final s in skills) {
    final nom = s.nom ?? '';
    final niveau = s.niveau ?? 3;
    // Separer par virgule et point-virgule, mais PAS par /
    // (pour garder CI/CD, API REST, etc.)
    final parts = nom.split(RegExp(r'[,;]+'));
    for (final p in parts) {
      final trimmed = p.trim();
      if (trimmed.isNotEmpty) result.add(_SkillData(trimmed, niveau));
    }
  }
  return result;
}

// Nettoie le texte : Unicode, markdown, accents courants
String _sanitize(String text) {
  return text
      // Markdown
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // **gras** → gras
      .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // *italique* → italique
      .replaceAll(RegExp(r'^#{1,3}\s+', multiLine: true), '') // # titre → titre
      // Unicode
      .replaceAll('\u2022', '-') // • → -
      .replaceAll('\u00B7', '-') // · → -
      .replaceAll('\u2013', '-') // – → -
      .replaceAll('\u2014', '-') // — → -
      .replaceAll('\u2018', "'") // ' → '
      .replaceAll('\u2019', "'") // ' → '
      .replaceAll('\u201C', '"') // " → "
      .replaceAll('\u201D', '"') // " → "
      .replaceAll('\u0153', 'oe') // œ → oe
      .replaceAll('\u0152', 'OE') // Œ → OE
      .replaceAll('\u2026', '...') // … → ...
      .replaceAll('\u00ab', '"') // « → "
      .replaceAll('\u00bb', '"'); // » → "
}
