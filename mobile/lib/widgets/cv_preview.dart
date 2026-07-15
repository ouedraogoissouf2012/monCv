import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cv.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_colors.dart';
import '../utils/cv_levels.dart';

/// Preview du CV — reproduit exactement le layout de chaque template PDF.
class CvPreviewWidget extends StatelessWidget {
  final Cv cv;
  const CvPreviewWidget({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(4),
            child: _buildTemplate(),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplate() {
    switch (cv.style.templateId) {
      case 'classique':
        return _ClassiqueTemplate(cv: cv);
      case 'minimaliste':
        return _MinimalisteTemplate(cv: cv);
      case 'creatif':
        return _CreatifTemplate(cv: cv);
      case 'executive':
        return _ExecutiveTemplate(cv: cv);
      case 'ats':
        return _AtsTemplate(cv: cv);
      case 'moderne':
      default:
        return _ModerneTemplate(cv: cv);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS PARTAGES
// ══════════════════════════════════════════════════════════════════════════════

String _fmt(DateTime? d) {
  if (d == null) return '';
  return '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _dateRange(DateTime? debut, DateTime? fin, String ongoing,
    {bool actuel = false}) {
  final d = _fmt(debut);
  if (actuel || fin == null && debut != null)
    return d.isEmpty ? ongoing : '$d - $ongoing';
  final f = _fmt(fin);
  if (d.isEmpty && f.isEmpty) return '';
  if (f.isEmpty) return d;
  if (d == f) return d;
  if (debut?.year == fin?.year) return '${debut!.year}';
  return '$d - $f';
}

class _PreviewSkillData {
  final String name;
  final int level;

  const _PreviewSkillData(this.name, this.level);
}

List<_PreviewSkillData> _splitSkillsWithLevel(List<Skill> skills) {
  final result = <_PreviewSkillData>[];
  for (final s in skills) {
    for (final p in (s.nom ?? '').split(RegExp(r'[,;]+'))) {
      final t = p.trim();
      if (t.isNotEmpty) {
        result.add(_PreviewSkillData(t, s.niveau ?? 3));
      }
    }
  }
  return result;
}

TextStyle _font(String fontFamily, TextStyle base) {
  try {
    return GoogleFonts.getFont(fontFamily, textStyle: base);
  } catch (_) {
    return base;
  }
}

// ── Section header partage ──
Widget _sectionTitle(String title, Color accent) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 13,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(1.5),
              )),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.8,
              )),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Container(height: 0.5, color: accent.withValues(alpha: 0.3))),
        ],
      ),
    );

// ── Experience entry ──
Widget _expEntry(Experience e, Color accent, AppLocalizations l) {
  final date =
      _dateRange(e.dateDebut, e.dateFin, l.inProgress, actuel: e.actuel);
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(e.poste ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
                    ))),
            if (date.isNotEmpty)
              Text(date,
                  style: TextStyle(
                      fontSize: 9, color: accent, fontWeight: FontWeight.w700)),
          ],
        ),
        if (e.entreprise?.isNotEmpty == true || e.lieu?.isNotEmpty == true)
          Text(
              [e.entreprise, e.lieu]
                  .where((s) => s?.isNotEmpty == true)
                  .join(' - '),
              style:
                  const TextStyle(fontSize: 10, color: AppColors.neutral450)),
        if (e.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          ..._buildDescLines(e.description!, accent),
        ],
      ],
    ),
  );
}

List<Widget> _buildDescLines(String desc, Color accent) {
  final lines = desc.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length <= 1 && !desc.contains('- ')) {
    return [
      Text(desc,
          style: const TextStyle(
              fontSize: 10, color: AppColors.neutral700, height: 1.4))
    ];
  }
  return lines.map((line) {
    final t = line.trim();
    final isBullet = t.startsWith('- ') || t.startsWith('* ');
    final text = isBullet ? t.substring(2) : t;
    if (isBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2, left: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 5, right: 6),
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(2))),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.neutral700, height: 1.4))),
        ]),
      );
    }
    return Text(text,
        style: const TextStyle(
            fontSize: 10, color: AppColors.neutral700, height: 1.4));
  }).toList();
}

// ── Education entry ──
Widget _eduEntry(Education e, Color accent, AppLocalizations l) {
  final date = _dateRange(e.dateDebut, e.dateFin, l.inProgress);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(e.diplome ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900))),
          if (date.isNotEmpty)
            Text(date,
                style: TextStyle(
                    fontSize: 9, color: accent, fontWeight: FontWeight.w700)),
        ]),
        if (e.etablissement?.isNotEmpty == true)
          Text(e.etablissement!,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.neutral450)),
        if (e.description?.isNotEmpty == true)
          Text(e.description!,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      ],
    ),
  );
}

// ── Competences avec barres et vrai niveau ──
Widget _skillsBars(List<Skill> skills, Color accent, AppLocalizations l) {
  final data = _splitSkillsWithLevel(skills);
  return Column(
      children: data
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(
                      width: 90,
                      child: Text(s.name,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600))),
                  Expanded(
                      child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: skillLevelProgress(s.level),
                        minHeight: 4,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent)),
                  )),
                  const SizedBox(width: 6),
                  SizedBox(
                      width: 62,
                      child: Text(localizedSkillLevelLabel(l, s.level),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 7.5,
                              color: accent,
                              fontWeight: FontWeight.w600))),
                ]),
              ))
          .toList());
}

// ── Langues avec barres ──
Widget _langBars(List<Language> langs, Color accent, AppLocalizations l) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: langs
          .map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang.langue ?? '',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600)),
                            Text(localizedLanguageLevelDisplay(l, lang.niveau),
                                style: TextStyle(
                                    fontSize: 7.5,
                                    color: accent,
                                    fontWeight: FontWeight.w600)),
                          ]),
                      const SizedBox(height: 3),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                              value: languageLevelProgress(lang.niveau),
                              minHeight: 4,
                              backgroundColor: accent.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(accent))),
                    ]),
              ))
          .toList(),
    );

// ── Certification entry ──
Widget _certEntry(Certification c, Color accent) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(2.5))),
        Expanded(
            child: Text(c.nom ?? '',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600))),
        Text(_fmt(c.dateObtention),
            style: TextStyle(
                fontSize: 9, color: accent, fontWeight: FontWeight.w600)),
      ]),
    );

// ── Project entry ──
Widget _projEntry(Project p, Color accent) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.nom ?? '',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        if (p.technologies?.isNotEmpty == true)
          Text(p.technologies!,
              style: const TextStyle(fontSize: 9, color: AppColors.neutral450)),
        if (p.description?.isNotEmpty == true)
          Text(p.description!,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      ]),
    );

// ── Body sections (ordre: Profil > Competences+Langues > Experiences > Formations > Certif+Projets) ──
Widget _bodySections(Cv cv, Color accent, AppLocalizations l) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cv.personalInfo?.resumeProfessionnel?.isNotEmpty == true) ...[
          _sectionTitle(l.profile, accent),
          Text(cv.personalInfo!.resumeProfessionnel!,
              style: const TextStyle(
                  fontSize: 10, height: 1.5, color: AppColors.neutral700)),
        ],
        if (cv.skills.isNotEmpty || cv.languages.isNotEmpty)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (cv.skills.isNotEmpty)
              Expanded(
                  flex: 3,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(l.skills, accent),
                        _skillsBars(cv.skills, accent, l),
                      ])),
            if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
              const SizedBox(width: 20),
            if (cv.languages.isNotEmpty)
              Expanded(
                  flex: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(l.languages, accent),
                        _langBars(cv.languages, accent, l),
                      ])),
          ]),
        if (cv.experiences.isNotEmpty) ...[
          _sectionTitle(l.experiences, accent),
          ...cv.experiences.map((e) => _expEntry(e, accent, l)),
        ],
        if (cv.educations.isNotEmpty) ...[
          _sectionTitle(l.education, accent),
          ...cv.educations.map((e) => _eduEntry(e, accent, l)),
        ],
        if (cv.certifications.isNotEmpty || cv.projects.isNotEmpty)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (cv.certifications.isNotEmpty)
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _sectionTitle(l.certifications, accent),
                    ...cv.certifications.map((c) => _certEntry(c, accent)),
                  ])),
            if (cv.certifications.isNotEmpty && cv.projects.isNotEmpty)
              const SizedBox(width: 20),
            if (cv.projects.isNotEmpty)
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _sectionTitle(l.projects, accent),
                    ...cv.projects.map((p) => _projEntry(p, accent)),
                  ])),
          ]),
      ],
    );

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 1 : MODERNE — header colore centre + body
// ══════════════════════════════════════════════════════════════════════════════

class _ModerneTemplate extends StatelessWidget {
  final Cv cv;
  const _ModerneTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true)
        '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
    ].join('   |   ');

    return DefaultTextStyle(
      style: _font(cv.style.fontFamily,
          const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 22),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Column(children: [
            // Photo
            if (info?.photoUrl?.isNotEmpty == true) ...[
              ClipOval(
                child: Image.network(info!.photoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(Icons.person,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 32))),
              ),
              const SizedBox(height: 10),
            ],
            Text(
                '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim().toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3)),
            if (info?.titrePoste?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(info!.titrePoste!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Container(
                height: 0.4,
                width: 200,
                color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(contact,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.white)),
          ]),
        ),
        // Body
        Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
            child: _bodySections(cv, accent, l)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 2 : CLASSIQUE — header blanc centre + double barre
// ══════════════════════════════════════════════════════════════════════════════

class _ClassiqueTemplate extends StatelessWidget {
  final Cv cv;
  const _ClassiqueTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true) info!.ville!,
    ].join('   |   ');

    return DefaultTextStyle(
      style: _font(cv.style.fontFamily,
          const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: accent))),
          if (info?.titrePoste?.isNotEmpty == true)
            Center(
                child: Text(info!.titrePoste!,
                    style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Center(
              child: Text(contact,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.neutral450))),
          const SizedBox(height: 10),
          Container(height: 2.5, color: accent),
          const SizedBox(height: 1),
          Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
          _bodySections(cv, accent, l),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 3 : MINIMALISTE — nom grand gauche, contact discret
// ══════════════════════════════════════════════════════════════════════════════

class _MinimalisteTemplate extends StatelessWidget {
  final Cv cv;
  const _MinimalisteTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true) info!.ville!,
    ].join('   |   ');

    return DefaultTextStyle(
      style: _font(cv.style.fontFamily,
          const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          if (info?.titrePoste?.isNotEmpty == true)
            Text(info!.titrePoste!,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.neutral300)),
          const SizedBox(height: 8),
          Text(contact,
              style: const TextStyle(fontSize: 9, color: AppColors.neutral300)),
          const SizedBox(height: 14),
          Container(height: 0.8, color: AppColors.neutral100),
          _bodySections(cv, accent, l),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 4 : CREATIF — sidebar coloree + contenu droite (identique au PDF)
// ══════════════════════════════════════════════════════════════════════════════

class _CreatifTemplate extends StatelessWidget {
  final Cv cv;
  const _CreatifTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final splitSkills = _splitSkillsWithLevel(cv.skills);

    return DefaultTextStyle(
      style: _font(cv.style.fontFamily,
          const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Sidebar ──
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Photo dans sidebar
              if (info?.photoUrl?.isNotEmpty == true) ...[
                Center(
                    child: ClipOval(
                  child: Image.network(info!.photoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Icon(Icons.person,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 28))),
                )),
                const SizedBox(height: 10),
              ],
              Text('${info?.prenom ?? ''}\n${info?.nom ?? ''}'.trim(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2)),
              if (info?.titrePoste?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Container(height: 0.4, color: Colors.white),
                const SizedBox(height: 6),
                Text(info!.titrePoste!,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              _sideLabel(l.information.toUpperCase()),
              if (info?.email?.isNotEmpty == true) _sideText(info!.email!),
              if (info?.telephone?.isNotEmpty == true)
                _sideText(info!.telephone!),
              if (info?.ville?.isNotEmpty == true) _sideText(info!.ville!),
              // Competences
              if (splitSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sideLabel(l.skills.toUpperCase()),
                ...splitSkills.take(10).map((skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                      child: Text(skill.name,
                                          style: const TextStyle(
                                              fontSize: 8.5,
                                              color: Colors.white))),
                                  Text(localizedSkillLevelLabel(l, skill.level),
                                      style: const TextStyle(
                                          fontSize: 6.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                ]),
                            const SizedBox(height: 2),
                            Row(
                                children: List.generate(
                                    5,
                                    (i) => Container(
                                          width: 8,
                                          height: 3.5,
                                          margin:
                                              const EdgeInsets.only(right: 2),
                                          decoration: BoxDecoration(
                                            color: i < skill.level.clamp(1, 5)
                                                ? Colors.white
                                                : Colors.white
                                                    .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(1.5),
                                          ),
                                        ))),
                          ]),
                    )),
              ],
              // Langues
              if (cv.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sideLabel(l.languages.toUpperCase()),
                ...cv.languages.map((lang) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang.langue ?? '',
                                style: const TextStyle(
                                    fontSize: 8.5, color: Colors.white)),
                            Text(localizedLanguageLevelLabel(l, lang.niveau),
                                style: const TextStyle(
                                    fontSize: 6.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    )),
              ],
              // Certifications
              if (cv.certifications.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sideLabel(l.certifications.toUpperCase()),
                ...cv.certifications.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(c.nom ?? '',
                          style: const TextStyle(
                              fontSize: 8.5, color: Colors.white)),
                    )),
              ],
            ]),
          ),
          // ── Contenu principal ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
                      _sectionTitle(l.professionalSummary, accent),
                      Text(info!.resumeProfessionnel!,
                          style: const TextStyle(
                              fontSize: 10,
                              height: 1.4,
                              color: AppColors.neutral700)),
                    ],
                    if (cv.experiences.isNotEmpty) ...[
                      _sectionTitle(l.experiences, accent),
                      ...cv.experiences.map((e) => _expEntry(e, accent, l)),
                    ],
                    if (cv.educations.isNotEmpty) ...[
                      _sectionTitle(l.education, accent),
                      ...cv.educations.map((e) => _eduEntry(e, accent, l)),
                    ],
                    if (cv.projects.isNotEmpty) ...[
                      _sectionTitle(l.projects, accent),
                      ...cv.projects.map((p) => _projEntry(p, accent)),
                    ],
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sideLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Container(height: 0.4, color: Colors.white),
        ]),
      );

  Widget _sideText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(text,
            style: const TextStyle(fontSize: 8.5, color: Colors.white)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 5 : EXECUTIVE — nom gauche, contact droite, barre epaisse
// ══════════════════════════════════════════════════════════════════════════════

class _ExecutiveTemplate extends StatelessWidget {
  final Cv cv;
  const _ExecutiveTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;

    return DefaultTextStyle(
      style: _font(cv.style.fontFamily,
          const TextStyle(fontSize: 10, color: AppColors.neutral700)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  if (info?.titrePoste?.isNotEmpty == true)
                    Text(info!.titrePoste!,
                        style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w700)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (info?.email?.isNotEmpty == true)
                Text(info!.email!,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.neutral450)),
              if (info?.telephone?.isNotEmpty == true)
                Text(info!.telephone!,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.neutral450)),
              if (info?.ville?.isNotEmpty == true)
                Text(
                    '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.neutral450)),
            ]),
          ]),
          const SizedBox(height: 8),
          Container(height: 3, color: accent),
          const SizedBox(height: 1),
          Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
          _bodySections(cv, accent, l),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 6 : ATS-SAFE — 1 colonne, texte pur, 100% compatible ATS
// ══════════════════════════════════════════════════════════════════════════════

class _AtsTemplate extends StatelessWidget {
  final Cv cv;
  const _AtsTemplate({required this.cv});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final info = cv.personalInfo;
    const black = AppColors.neutral900;
    const grey = AppColors.neutral450;
    final splitSkills = _splitSkillsWithLevel(cv.skills);
    final contact = [
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true)
        '${info!.ville}${info.pays?.isNotEmpty == true ? ', ${info.pays}' : ''}',
    ].join('  |  ');

    Widget atsSection(String title) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: black,
                  letterSpacing: 1,
                )),
            const SizedBox(height: 2),
            Container(height: 1, color: black),
          ]),
        );

    return DefaultTextStyle(
      style: _font(
          cv.style.fontFamily, const TextStyle(fontSize: 11, color: black)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim(),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: black)),
          if (info?.titrePoste?.isNotEmpty == true)
            Text(info!.titrePoste!,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: grey)),
          const SizedBox(height: 6),
          Text(contact, style: const TextStyle(fontSize: 10, color: grey)),
          if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
            atsSection(l.profile),
            Text(info!.resumeProfessionnel!,
                style:
                    const TextStyle(fontSize: 11, height: 1.5, color: black)),
          ],
          if (splitSkills.isNotEmpty) ...[
            atsSection(l.skills),
            Text(
              splitSkills
                  .map((skill) =>
                      '${skill.name} (${localizedSkillLevelLabel(l, skill.level)})')
                  .join('  -  '),
              style: const TextStyle(fontSize: 11, color: black),
            ),
          ],
          if (cv.languages.isNotEmpty) ...[
            atsSection(l.languages),
            Text(
                cv.languages
                    .map((lang) =>
                        '${lang.langue ?? ''} (${localizedLanguageLevelDisplay(l, lang.niveau)})')
                    .join('  -  '),
                style: const TextStyle(fontSize: 11, color: black)),
          ],
          if (cv.experiences.isNotEmpty) ...[
            atsSection(l.experiences),
            ...cv.experiences.map((e) {
              final date = _dateRange(e.dateDebut, e.dateFin, l.inProgress,
                  actuel: e.actuel);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(e.poste ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: black))),
                        if (date.isNotEmpty)
                          Text(date,
                              style:
                                  const TextStyle(fontSize: 10, color: grey)),
                      ]),
                      Text(
                          [e.entreprise, e.lieu]
                              .where((s) => s?.isNotEmpty == true)
                              .join(', '),
                          style: const TextStyle(fontSize: 10, color: grey)),
                      if (e.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        ..._buildDescLines(e.description!, black),
                      ],
                    ]),
              );
            }),
          ],
          if (cv.educations.isNotEmpty) ...[
            atsSection(l.education),
            ...cv.educations.map((e) {
              final date = _dateRange(e.dateDebut, e.dateFin, l.inProgress);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(e.diplome ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: black))),
                        if (date.isNotEmpty)
                          Text(date,
                              style:
                                  const TextStyle(fontSize: 10, color: grey)),
                      ]),
                      if (e.etablissement?.isNotEmpty == true)
                        Text(e.etablissement!,
                            style: const TextStyle(fontSize: 10, color: grey)),
                    ]),
              );
            }),
          ],
          if (cv.certifications.isNotEmpty) ...[
            atsSection(l.certifications),
            ...cv.certifications.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Expanded(
                        child: Text(c.nom ?? '',
                            style:
                                const TextStyle(fontSize: 11, color: black))),
                    Text(_fmt(c.dateObtention),
                        style: const TextStyle(fontSize: 10, color: grey)),
                  ]),
                )),
          ],
        ]),
      ),
    );
  }
}
