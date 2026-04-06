import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv.dart';

// ── Charger photo depuis URL ────────────────────────────────────────────────

Future<pw.MemoryImage?> _loadPhoto(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return pw.MemoryImage(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

// ── Point d'entrée ──────────────────────────────────────────────────────────

Future<Uint8List> generateCvPdf(Cv cv) async {
  final style = cv.style;
  final color = PdfColor.fromInt(style.primaryColor.toARGB32());
  final photo = await _loadPhoto(cv.personalInfo?.photoUrl);

  switch (style.templateId) {
    case 'classique':
      return _buildClassique(cv, color, photo: photo);
    case 'minimaliste':
      return _buildMinimaliste(cv, color, photo: photo);
    case 'creatif':
      return _buildCreatif(cv, color, photo: photo);
    case 'executive':
      return _buildExecutive(cv, color, photo: photo);
    case 'ats':
      return _buildAts(cv, color);
    case 'moderne':
    default:
      return _buildModerne(cv, color, photo: photo);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime? d) {
  if (d == null) return '';
  return '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _dateRange(DateTime? debut, DateTime? fin, {bool actuel = false}) {
  final d = _fmtDate(debut);
  if (actuel || fin == null && debut != null) return d.isEmpty ? 'En cours' : '$d - En cours';
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
    final parts = nom.split(RegExp(r'[,;/]+'));
    for (final p in parts) {
      final trimmed = p.trim();
      if (trimmed.isNotEmpty) result.add(_SkillData(trimmed, niveau));
    }
  }
  return result;
}

List<String> _splitSkills(List<Skill> skills) =>
    _splitSkillsWithLevel(skills).map((s) => s.name).toList();


// Nettoie le texte : Unicode, markdown, accents courants
String _sanitize(String text) {
  return text
      // Markdown
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')  // **gras** → gras
      .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')       // *italique* → italique
      .replaceAll(RegExp(r'^#{1,3}\s+', multiLine: true), '')  // # titre → titre
      // Unicode
      .replaceAll('\u2022', '-')   // • → -
      .replaceAll('\u00B7', '-')   // · → -
      .replaceAll('\u2013', '-')   // – → -
      .replaceAll('\u2014', '-')   // — → -
      .replaceAll('\u2018', "'")   // ' → '
      .replaceAll('\u2019', "'")   // ' → '
      .replaceAll('\u201C', '"')   // " → "
      .replaceAll('\u201D', '"')   // " → "
      .replaceAll('\u0153', 'oe')  // œ → oe
      .replaceAll('\u0152', 'OE')  // Œ → OE
      .replaceAll('\u2026', '...')  // … → ...
      .replaceAll('\u00ab', '"')   // « → "
      .replaceAll('\u00bb', '"');  // » → "
}

pw.TextStyle _bodyStyle({double size = 8.5, PdfColor? color, double height = 1.35}) => pw.TextStyle(
      fontSize: size,
      color: color ?? PdfColors.grey800,
      lineSpacing: height,
    );

pw.TextStyle _boldStyle({double size = 9.5, PdfColor? color}) => pw.TextStyle(
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColor.fromHex('#1a1a1a'),
    );

// Section header: colored left bar + title + fine line
pw.Widget _sectionHeader(String title, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5, top: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 3, height: 12, decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1.5)),
          )),
          pw.SizedBox(width: 8),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(height: 0.5, decoration: pw.BoxDecoration(
              color: PdfColor(accent.red, accent.green, accent.blue, 0.3),
            )),
          ),
        ],
      ),
    );

// Date alignee a droite
pw.Widget _datePill(String text, PdfColor accent) => pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 7.5,
        color: accent,
        fontWeight: pw.FontWeight.bold,
      ),
    );

// Barre de competence visuelle


// Bullet dot
pw.Widget _dot(PdfColor accent) => pw.Container(
      width: 6,
      height: 6,
      margin: const pw.EdgeInsets.only(top: 2.5, right: 8),
      decoration: pw.BoxDecoration(
        color: accent,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
    );

// Experience item
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
              _datePill(_dateRange(e.dateDebut, e.dateFin, actuel: e.actuel), accent),
            ],
          ),
          // Ligne 2: Entreprise + Lieu
          if (e.entreprise?.isNotEmpty == true || e.lieu?.isNotEmpty == true) ...[
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
              width: 4, height: 4,
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
pw.Widget _educationItem(Education e, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _dot(accent),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        e.diplome ?? '',
                        style: _boldStyle(size: 9.5),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    _datePill(_dateRange(e.dateDebut, e.dateFin), accent),
                  ],
                ),
                if (e.etablissement?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    e.etablissement!,
                    style: _bodyStyle(size: 8.5, color: PdfColors.grey600),
                  ),
                ],
                if (e.domaine?.isNotEmpty == true)
                  pw.Text(e.domaine!, style: _bodyStyle(size: 8, color: PdfColors.grey500)),
                if (e.description?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(_sanitize(e.description!), style: _bodyStyle(size: 9)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

// Skills: barres de progression avec vrai niveau
pw.Widget _skillsSection(List<Skill> skills, PdfColor accent) {
  final splitData = _splitSkillsWithLevel(skills);
  return pw.Column(
    children: splitData.map((s) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(s.name, style: pw.TextStyle(
            fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900,
          )),
        ),
        pw.Expanded(
          child: pw.ClipRRect(
            horizontalRadius: 1.5, verticalRadius: 1.5,
            child: pw.LinearProgressIndicator(
              value: s.niveau / 5, minHeight: 3,
              backgroundColor: PdfColor(accent.red, accent.green, accent.blue, 0.12),
              valueColor: accent,
            ),
          ),
        ),
        // Pas de label texte — la barre suffit
      ]),
    )).toList(),
  );
}

// Langues: nom + label descriptif + barre
pw.Widget _languagesSection(List<Language> langs, PdfColor accent) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: langs.map((l) {
        final label = _niveauLabel(l.niveau);
        final level = _niveauToDouble(l.niveau);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_sanitize(l.langue ?? ''),
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  pw.Text(label,
                      style: pw.TextStyle(fontSize: 7.5, color: accent, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.ClipRRect(
                horizontalRadius: 1.5,
                verticalRadius: 1.5,
                child: pw.LinearProgressIndicator(
                  value: level,
                  minHeight: 3,
                  backgroundColor: PdfColor(accent.red, accent.green, accent.blue, 0.12),
                  valueColor: accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

String _niveauLabel(String? n) {
  switch (n) {
    case 'A1': return 'Debutant';
    case 'A2': return 'Elementaire';
    case 'B1': return 'Intermediaire';
    case 'B2': return 'Avance';
    case 'C1': return 'Courant';
    case 'C2': return 'Bilingue';
    case 'NATIF': return 'Langue maternelle';
    default: return n ?? '';
  }
}

double _niveauToDouble(String? n) {
  switch (n) {
    case 'A1': return 0.15;
    case 'A2': return 0.30;
    case 'B1': return 0.50;
    case 'B2': return 0.65;
    case 'C1': return 0.82;
    case 'C2': return 0.95;
    case 'NATIF': return 1.0;
    default: return 0.5;
  }
}

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
                        pw.Text(c.organisme!, style: _bodyStyle(size: 8, color: PdfColors.grey600)),
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
                  pw.Text(_sanitize(p.description!), style: _bodyStyle(size: 9)),
              ],
            ),
          ),
        ],
      ),
    );

// Sidebar mini bar for Créatif template
pw.Widget _miniBar(int niveau, PdfColor color) {
  final filled = niveau.clamp(1, 5);
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: List.generate(5, (i) {
      return pw.Container(
        width: 8,
        height: 4,
        margin: const pw.EdgeInsets.only(right: 2),
        decoration: pw.BoxDecoration(
          color: i < filled
              ? color
              : PdfColor(color.red, color.green, color.blue, 0.3),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
      );
    }),
  );
}

// ── TEMPLATE 1 : MODERNE ─────────────────────────────────────────────────────

Future<Uint8List> _buildModerne(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) async {
  final doc = pw.Document();
  final info = cv.personalInfo;
  final contactItems = <String>[
    if (info?.email?.isNotEmpty == true) info!.email!,
    if (info?.telephone?.isNotEmpty == true) info!.telephone!,
    if (info?.ville?.isNotEmpty == true)
      '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
  ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (ctx) => [
      // ── HEADER ──
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 24),
        decoration: pw.BoxDecoration(color: accent),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (photo != null) ...[
              pw.ClipOval(
                child: pw.Image(photo, width: 60, height: 60, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Text(
              _sanitize('${info?.prenom ?? ''} ${info?.nom ?? ''}').trim().toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 4,
              ),
            ),
            if (info?.titrePoste?.isNotEmpty == true) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                _sanitize(info!.titrePoste!),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                  fontStyle: pw.FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Container(height: 0.4, width: 250, decoration: pw.BoxDecoration(
              color: PdfColor(1, 1, 1, 0.4),
            )),
            pw.SizedBox(height: 10),
            pw.Text(
              contactItems.map(_sanitize).join('   |   '),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
            ),
          ],
        ),
      ),

      // ── BODY ──
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(40, 16, 40, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. Resume
            if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
              _sectionHeader('Profil', accent),
              pw.Text(_sanitize(info!.resumeProfessionnel!), style: _bodyStyle(size: 8.5)),
            ],

            // 2. Competences + Langues (cote a cote, AVANT les experiences)
            if (cv.skills.isNotEmpty || cv.languages.isNotEmpty)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty)
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Competences', accent),
                          _skillsSection(cv.skills, accent),
                        ],
                      ),
                    ),
                  if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
                    pw.SizedBox(width: 24),
                  if (cv.languages.isNotEmpty)
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Langues', accent),
                          _languagesSection(cv.languages, accent),
                        ],
                      ),
                    ),
                ],
              ),

            // 3. Experiences
            if (cv.experiences.isNotEmpty) ...[
              _sectionHeader('Experiences professionnelles', accent),
              ...cv.experiences.map((e) => _experienceItem(e, accent)),
            ],

            // 4. Formations
            if (cv.educations.isNotEmpty) ...[
              _sectionHeader('Formations', accent),
              ...cv.educations.map((e) => _educationItem(e, accent)),
            ],

            // 5. Certifications + Projets cote a cote
            if (cv.certifications.isNotEmpty || cv.projects.isNotEmpty)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (cv.certifications.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Certifications', accent),
                          ...cv.certifications.map((c) => _certItem(c, accent)),
                        ],
                      ),
                    ),
                  if (cv.certifications.isNotEmpty && cv.projects.isNotEmpty)
                    pw.SizedBox(width: 24),
                  if (cv.projects.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Projets', accent),
                          ...cv.projects.map((p) => _projectItem(p, accent)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ],
  ));

  return doc.save();
}


// ── TEMPLATE 2 : CLASSIQUE ───────────────────────────────────────────────────

Future<Uint8List> _buildClassique(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) async {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    build: (ctx) => [
      // En-tête centré avec accent
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style: pw.TextStyle(
                  fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            if (info?.titrePoste?.isNotEmpty == true) ...[
              pw.SizedBox(height: 4),
              pw.Text(info!.titrePoste!,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              [
                if (info?.email?.isNotEmpty == true) info!.email!,
                if (info?.telephone?.isNotEmpty == true) info!.telephone!,
                if (info?.ville?.isNotEmpty == true) info!.ville!,
              ].join('   |   '),
              style: _bodyStyle(size: 8.5, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(height: 2, decoration: pw.BoxDecoration(color: accent)),
      pw.SizedBox(height: 2),
      pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: PdfColor(accent.red, accent.green, accent.blue, 0.3))),
      pw.SizedBox(height: 16),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        _sectionHeader('Résumé professionnel', accent),
        pw.Text(_sanitize(info!.resumeProfessionnel!), style: _bodyStyle(size: 9.5)),
        pw.SizedBox(height: 12),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences professionnelles', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 4),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 4),
      ],
      if (cv.skills.isNotEmpty) ...[
        _sectionHeader('Compétences', accent),
        pw.SizedBox(height: 4),
        _skillsSection(cv.skills, accent),
        pw.SizedBox(height: 10),
      ],
      if (cv.languages.isNotEmpty) ...[
        _sectionHeader('Langues', accent),
        pw.SizedBox(height: 4),
        _languagesSection(cv.languages, accent),
        pw.SizedBox(height: 10),
      ],
    ],
  ));
  return doc.save();
}

// ── TEMPLATE 3 : MINIMALISTE ─────────────────────────────────────────────────

Future<Uint8List> _buildMinimaliste(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) async {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 52, vertical: 44),
    build: (ctx) => [
      pw.Text(
        '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
        style: pw.TextStyle(
            fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
      if (info?.titrePoste?.isNotEmpty == true) ...[
        pw.SizedBox(height: 2),
        pw.Text(info!.titrePoste!,
            style: _bodyStyle(size: 11, color: PdfColors.grey600)),
      ],
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          if (info?.email?.isNotEmpty == true)
            pw.Text(info!.email!, style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          if (info?.telephone?.isNotEmpty == true) ...[
            pw.Text('   |   ', style: _bodyStyle(size: 8.5, color: PdfColors.grey400)),
            pw.Text(info!.telephone!, style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          ],
          if (info?.ville?.isNotEmpty == true) ...[
            pw.Text('   |   ', style: _bodyStyle(size: 8.5, color: PdfColors.grey400)),
            pw.Text(info!.ville!, style: _bodyStyle(size: 8.5, color: PdfColors.grey600)),
          ],
        ],
      ),
      pw.SizedBox(height: 20),
      pw.Container(height: 0.8, decoration: pw.BoxDecoration(color: PdfColors.grey300)),
      pw.SizedBox(height: 20),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        pw.Text(_sanitize(info!.resumeProfessionnel!), style: _bodyStyle(size: 9.5)),
        pw.SizedBox(height: 16),
        pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: PdfColors.grey200)),
        pw.SizedBox(height: 16),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 8),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 8),
      ],
      if (cv.skills.isNotEmpty) ...[
        _sectionHeader('Compétences', accent),
        pw.SizedBox(height: 4),
        _skillsSection(cv.skills, accent),
        pw.SizedBox(height: 12),
      ],
      if (cv.languages.isNotEmpty) ...[
        _sectionHeader('Langues', accent),
        pw.SizedBox(height: 4),
        _languagesSection(cv.languages, accent),
      ],
    ],
  ));
  return doc.save();
}

// ── TEMPLATE 4 : CRÉATIF (sidebar) ───────────────────────────────────────────

Future<Uint8List> _buildCreatif(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) async {
  final doc = pw.Document();
  final info = cv.personalInfo;
  const sidebarWidth = 185.0;
  final splitNames = _splitSkills(cv.skills);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (ctx) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Sidebar ──
        pw.Container(
          width: sidebarWidth,
          decoration: pw.BoxDecoration(color: accent),
          padding: const pw.EdgeInsets.fromLTRB(18, 28, 18, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Photo
              if (photo != null) ...[
                pw.Center(child: pw.ClipOval(
                  child: pw.Image(photo, width: 55, height: 55, fit: pw.BoxFit.cover),
                )),
                pw.SizedBox(height: 10),
              ],
              // Nom
              pw.Text(
                _sanitize('${info?.prenom ?? ''}\n${info?.nom ?? ''}'.trim()),
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    lineSpacing: 2),
              ),
              if (info?.titrePoste?.isNotEmpty == true) ...[
                pw.SizedBox(height: 8),
                pw.Container(height: 0.4, decoration: const pw.BoxDecoration(color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Text(_sanitize(info!.titrePoste!),
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontStyle: pw.FontStyle.italic)),
              ],
              // Contact
              pw.SizedBox(height: 20),
              _sideSection('CONTACT'),
              if (info?.email?.isNotEmpty == true)
                _sideItem(_sanitize(info!.email!)),
              if (info?.telephone?.isNotEmpty == true)
                _sideItem(_sanitize(info!.telephone!)),
              if (info?.ville?.isNotEmpty == true)
                _sideItem(_sanitize(info!.ville!)),
              // Competences separees avec barres
              if (splitNames.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('COMPETENCES'),
                ...splitNames.take(10).map((name) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_sanitize(name),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                          pw.SizedBox(height: 2),
                          _miniBar(3, PdfColors.white),
                        ],
                      ),
                    )),
              ],
              // Langues
              if (cv.languages.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('LANGUES'),
                ...cv.languages.map((l) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(_sanitize(l.langue ?? ''),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                          pw.Text(l.niveau ?? '',
                              style: pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
              // Certifications
              if (cv.certifications.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sideSection('CERTIFICATIONS'),
                ...cv.certifications.map((c) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(_sanitize(c.nom ?? ''),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                    )),
              ],
            ],
          ),
        ),
        // Contenu principal
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
                  _sectionHeader('Résumé', accent),
                  pw.Text(_sanitize(info!.resumeProfessionnel!),
                      style: _bodyStyle(size: 9)),
                  pw.SizedBox(height: 16),
                ],
                if (cv.experiences.isNotEmpty) ...[
                  _sectionHeader('Expériences', accent),
                  ...cv.experiences.map((e) => _experienceItem(e, accent)),
                  pw.SizedBox(height: 8),
                ],
                if (cv.educations.isNotEmpty) ...[
                  _sectionHeader('Formations', accent),
                  ...cv.educations.map((e) => _educationItem(e, accent)),
                  pw.SizedBox(height: 8),
                ],
                if (cv.certifications.isNotEmpty) ...[
                  _sectionHeader('Certifications', accent),
                  ...cv.certifications.map((c) => _certItem(c, accent)),
                ],
                if (cv.projects.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _sectionHeader('Projets', accent),
                  ...cv.projects.map((p) => _projectItem(p, accent)),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  ));
  return doc.save();
}

pw.Widget _sideSection(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 1.2),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: PdfColors.white)),
        ],
      ),
    );

pw.Widget _sideItem(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
    );

// ── TEMPLATE 5 : EXECUTIVE ───────────────────────────────────────────────────

Future<Uint8List> _buildExecutive(Cv cv, PdfColor accent, {pw.MemoryImage? photo}) async {
  final doc = pw.Document();
  final info = cv.personalInfo;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
    build: (ctx) => [
      // Header: nom gauche, contact droite
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(
              '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            if (info?.titrePoste?.isNotEmpty == true)
              pw.Text(info!.titrePoste!,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            if (info?.email?.isNotEmpty == true)
              pw.Text(info!.email!, style: _bodyStyle(size: 8.5)),
            if (info?.telephone?.isNotEmpty == true)
              pw.Text(info!.telephone!, style: _bodyStyle(size: 8.5)),
            if (info?.ville?.isNotEmpty == true)
              pw.Text(
                  '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
                  style: _bodyStyle(size: 8.5)),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 3, decoration: pw.BoxDecoration(color: accent)),
      pw.SizedBox(height: 1),
      pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: PdfColor(accent.red, accent.green, accent.blue, 0.3))),
      pw.SizedBox(height: 16),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        pw.Text(
          info!.resumeProfessionnel!,
          style: _bodyStyle(size: 9.5, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: PdfColors.grey300)),
        pw.SizedBox(height: 12),
      ],
      if (cv.experiences.isNotEmpty) ...[
        _sectionHeader('Expériences', accent),
        ...cv.experiences.map((e) => _experienceItem(e, accent)),
        pw.SizedBox(height: 6),
      ],
      if (cv.educations.isNotEmpty) ...[
        _sectionHeader('Formations', accent),
        ...cv.educations.map((e) => _educationItem(e, accent)),
        pw.SizedBox(height: 6),
      ],
      if (cv.skills.isNotEmpty || cv.languages.isNotEmpty) ...[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (cv.skills.isNotEmpty)
              pw.Expanded(
                flex: 3,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _sectionHeader('Competences', accent),
                  _skillsSection(cv.skills, accent),
                ]),
              ),
            if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
              pw.SizedBox(width: 24),
            if (cv.languages.isNotEmpty)
              pw.Expanded(
                flex: 2,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _sectionHeader('Langues', accent),
                  _languagesSection(cv.languages, accent),
                ]),
              ),
          ],
        ),
      ],
      if (cv.certifications.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionHeader('Certifications', accent),
        ...cv.certifications.map((c) => _certItem(c, accent)),
      ],
      if (cv.projects.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _sectionHeader('Projets', accent),
        ...cv.projects.map((p) => _projectItem(p, accent)),
      ],
    ],
  ));
  return doc.save();
}

// ── TEMPLATE 6 : ATS-SAFE ───────────────────────────────────────────────────
// 100% compatible ATS : 1 colonne, pas de graphiques, pas de photo,
// pas de barres, pas de couleur, texte pur.

Future<Uint8List> _buildAts(Cv cv, PdfColor accent) async {
  final doc = pw.Document();
  final info = cv.personalInfo;
  final black = PdfColors.black;
  final grey = PdfColors.grey700;
  final splitNames = _splitSkills(cv.skills);

  pw.Widget atsSection(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(
          fontSize: 10, fontWeight: pw.FontWeight.bold, color: black, letterSpacing: 1,
        )),
        pw.Container(height: 0.8, decoration: pw.BoxDecoration(color: black)),
      ],
    ),
  );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
    build: (ctx) => [
      pw.Text(
        _sanitize('${info?.prenom ?? ''} ${info?.nom ?? ''}').trim(),
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: black),
      ),
      if (info?.titrePoste?.isNotEmpty == true)
        pw.Text(_sanitize(info!.titrePoste!),
            style: pw.TextStyle(fontSize: 12, color: grey, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text(
        [
          if (info?.email?.isNotEmpty == true) _sanitize(info!.email!),
          if (info?.telephone?.isNotEmpty == true) _sanitize(info!.telephone!),
          if (info?.ville?.isNotEmpty == true)
            _sanitize('${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}'),
        ].join('  |  '),
        style: pw.TextStyle(fontSize: 9, color: grey),
      ),
      if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
        atsSection('Profil'),
        pw.Text(_sanitize(info!.resumeProfessionnel!),
            style: pw.TextStyle(fontSize: 10, color: black, lineSpacing: 1.3)),
      ],
      if (splitNames.isNotEmpty) ...[
        atsSection('Competences'),
        pw.Text(splitNames.join('  -  '), style: pw.TextStyle(fontSize: 10, color: black)),
      ],
      if (cv.languages.isNotEmpty) ...[
        atsSection('Langues'),
        pw.Text(
          cv.languages.map((l) => '${_sanitize(l.langue ?? '')} (${_niveauLabel(l.niveau)})').join('  -  '),
          style: pw.TextStyle(fontSize: 10, color: black),
        ),
      ],
      if (cv.experiences.isNotEmpty) ...[
        atsSection('Experience professionnelle'),
        ...cv.experiences.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(_sanitize(e.poste ?? ''), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: black)),
              pw.Text(_dateRange(e.dateDebut, e.dateFin, actuel: e.actuel), style: pw.TextStyle(fontSize: 9, color: grey)),
            ]),
            pw.Text(_sanitize([e.entreprise, e.lieu].where((s) => s?.isNotEmpty == true).join(', ')),
                style: pw.TextStyle(fontSize: 9, color: grey)),
            if (e.description?.isNotEmpty == true) ...[
              pw.SizedBox(height: 3),
              ..._buildDescriptionLines(_sanitize(e.description!), accent),
            ],
          ]),
        )),
      ],
      if (cv.educations.isNotEmpty) ...[
        atsSection('Formation'),
        ...cv.educations.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(e.diplome ?? '', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: black)),
              pw.Text(_dateRange(e.dateDebut, e.dateFin), style: pw.TextStyle(fontSize: 9, color: grey)),
            ]),
            if (e.etablissement?.isNotEmpty == true)
              pw.Text(_sanitize(e.etablissement!), style: pw.TextStyle(fontSize: 9, color: grey)),
          ]),
        )),
      ],
      if (cv.certifications.isNotEmpty) ...[
        atsSection('Certifications'),
        ...cv.certifications.map((c) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_sanitize(c.nom ?? ''), style: pw.TextStyle(fontSize: 10, color: black)),
            pw.Text(_fmtDate(c.dateObtention), style: pw.TextStyle(fontSize: 9, color: grey)),
          ],
        )),
      ],
    ],
  ));
  return doc.save();
}
