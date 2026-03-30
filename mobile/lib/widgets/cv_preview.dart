import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cv.dart';
import '../models/cv_style.dart';

/// Aperçu document d'un CV — rendu identique au PDF généré.
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
            child: _CvDocument(cv: cv),
          ),
        ),
      ),
    );
  }
}

// ── Document principal ────────────────────────────────────────────────────────

class _CvDocument extends StatelessWidget {
  final Cv cv;
  const _CvDocument({required this.cv});

  TextStyle _font(TextStyle base) {
    try {
      return GoogleFonts.getFont(cv.style.fontFamily, textStyle: base);
    } catch (_) {
      return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = cv.style.primaryColor;
    final info = cv.personalInfo;
    final templateId = cv.style.templateId;
    final name = '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim().isNotEmpty
        ? '${info?.prenom ?? ''} ${info?.nom ?? ''}'.trim()
        : cv.titre;

    TextStyle baseStyle;
    try {
      baseStyle = GoogleFonts.getFont(cv.style.fontFamily,
          textStyle: const TextStyle(fontSize: 12, color: Color(0xFF374151)));
    } catch (_) {
      baseStyle = const TextStyle(fontSize: 12, color: Color(0xFF374151));
    }

    return DefaultTextStyle(
      style: baseStyle,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── En-tête adapte au template ──
        _buildHeader(templateId, accent, info, name),

        // ── Corps ──
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profil
              if (info?.resumeProfessionnel?.isNotEmpty == true) ...[
                _SectionTitle(title: 'PROFIL', accent: accent),
                const SizedBox(height: 8),
                Text(
                  info!.resumeProfessionnel!,
                  style: _font(const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF374151))),
                ),
                const SizedBox(height: 12),
              ],

              // 2. Competences + Langues cote a cote
              if (cv.skills.isNotEmpty || cv.languages.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cv.skills.isNotEmpty)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'COMPETENCES', accent: accent),
                            const SizedBox(height: 8),
                            _SkillsGrid(skills: cv.skills, accent: accent),
                          ],
                        ),
                      ),
                    if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
                      const SizedBox(width: 20),
                    if (cv.languages.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'LANGUES', accent: accent),
                            const SizedBox(height: 8),
                            _LanguagesRow(languages: cv.languages, accent: accent),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // 3. Experiences
              if (cv.experiences.isNotEmpty) ...[
                _SectionTitle(title: 'EXPERIENCES PROFESSIONNELLES', accent: accent),
                const SizedBox(height: 8),
                ...cv.experiences.map((e) => _ExperienceEntry(exp: e, accent: accent)),
                const SizedBox(height: 4),
              ],

              // 4. Formations
              if (cv.educations.isNotEmpty) ...[
                _SectionTitle(title: 'FORMATIONS', accent: accent),
                const SizedBox(height: 8),
                ...cv.educations.map((e) => _EducationEntry(edu: e, accent: accent)),
                const SizedBox(height: 4),
              ],

              // 5. Certifications + Projets cote a cote
              if (cv.certifications.isNotEmpty || cv.projects.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cv.certifications.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'CERTIFICATIONS', accent: accent),
                            const SizedBox(height: 8),
                            ...cv.certifications.map((c) => _CertEntry(cert: c, accent: accent)),
                          ],
                        ),
                      ),
                    if (cv.certifications.isNotEmpty && cv.projects.isNotEmpty)
                      const SizedBox(width: 20),
                    if (cv.projects.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'PROJETS', accent: accent),
                            const SizedBox(height: 8),
                            ...cv.projects.map((p) => _ProjectEntry(proj: p, accent: accent)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildHeader(String templateId, Color accent, PersonalInfo? info, String name) {
    switch (templateId) {
      case 'classique':
        return _headerClassique(accent, info, name);
      case 'minimaliste':
        return _headerMinimaliste(accent, info, name);
      case 'creatif':
        return _headerCreatif(accent, info, name);
      case 'executive':
        return _headerExecutive(accent, info, name);
      case 'moderne':
      default:
        return _headerModerne(accent, info, name);
    }
  }

  // ── Moderne: header colore pleine largeur ──
  Widget _headerModerne(Color accent, PersonalInfo? info, String name) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(name.toUpperCase(),
              textAlign: TextAlign.center,
              style: _font(const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 2, height: 1.1,
              ))),
          if (info?.titrePoste?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(info!.titrePoste!,
                  style: _font(TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: accent,
                  ))),
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 0.5, width: 200, color: Colors.white),
          const SizedBox(height: 10),
          _contactRow(info, Colors.white),
        ],
      ),
    );
  }

  // ── Classique: header centre, nom + titre + separateur ──
  Widget _headerClassique(Color accent, PersonalInfo? info, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Column(
        children: [
          Text(name,
              textAlign: TextAlign.center,
              style: _font(const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF111827),
              ))),
          if (info?.titrePoste?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(info!.titrePoste!,
                style: _font(TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: accent,
                ))),
          ],
          const SizedBox(height: 10),
          _contactRow(info, const Color(0xFF6B7280)),
          const SizedBox(height: 12),
          Container(height: 2.5, color: accent),
          const SizedBox(height: 1),
          Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  // ── Minimaliste: nom grand + contact discret ──
  Widget _headerMinimaliste(Color accent, PersonalInfo? info, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: _font(const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF111827),
              ))),
          if (info?.titrePoste?.isNotEmpty == true)
            Text(info!.titrePoste!,
                style: _font(const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF),
                ))),
          const SizedBox(height: 10),
          _contactRow(info, const Color(0xFF9CA3AF)),
          const SizedBox(height: 14),
          Container(height: 0.8, color: const Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  // ── Creatif: sidebar coloree + contenu a droite ──
  Widget _headerCreatif(Color accent, PersonalInfo? info, String name) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: _font(const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
                    ))),
                if (info?.titrePoste?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(info!.titrePoste!,
                      style: _font(TextStyle(
                        fontSize: 11, fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85),
                      ))),
                ],
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info?.email?.isNotEmpty == true)
                _iconContact(Icons.email_outlined, info!.email!),
              if (info?.telephone?.isNotEmpty == true)
                _iconContact(Icons.phone_outlined, info!.telephone!),
              if (info?.ville?.isNotEmpty == true)
                _iconContact(Icons.location_on_outlined,
                    [info!.ville, info.pays].where((s) => s?.isNotEmpty == true).join(', ')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Executive: nom gauche, contact droite, barre epaisse ──
  Widget _headerExecutive(Color accent, PersonalInfo? info, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: _font(const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827),
                        ))),
                    if (info?.titrePoste?.isNotEmpty == true)
                      Text(info!.titrePoste!,
                          style: _font(TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                          ))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (info?.email?.isNotEmpty == true)
                    Text(info!.email!, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                  if (info?.telephone?.isNotEmpty == true)
                    Text(info!.telephone!, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                  if (info?.ville?.isNotEmpty == true)
                    Text([info!.ville, info.pays].where((s) => s?.isNotEmpty == true).join(', '),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 3, color: accent),
          const SizedBox(height: 1),
          Container(height: 0.5, color: accent.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _contactRow(PersonalInfo? info, Color color) {
    final items = <String>[
      if (info?.email?.isNotEmpty == true) info!.email!,
      if (info?.telephone?.isNotEmpty == true) info!.telephone!,
      if (info?.ville?.isNotEmpty == true)
        [info!.ville, info.pays].where((s) => s?.isNotEmpty == true).join(', '),
    ];
    return Text(
      items.join('  |  '),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 10, color: color),
    );
  }

  Widget _iconContact(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Titre de section ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color accent;
  const _SectionTitle({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: accent.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

// ── Helpers date ──────────────────────────────────────────────────────────────

String _fmt(DateTime? d) {
  if (d == null) return '';
  return '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Expérience ────────────────────────────────────────────────────────────────

class _ExperienceEntry extends StatelessWidget {
  final Experience exp;
  final Color accent;
  const _ExperienceEntry({required this.exp, required this.accent});

  @override
  Widget build(BuildContext context) {
    final dateEnd = exp.actuel ? 'Present' : _fmt(exp.dateFin);
    final period = [_fmt(exp.dateDebut), dateEnd]
        .where((s) => s.isNotEmpty)
        .join(' - ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 10),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.poste ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          if (exp.entreprise?.isNotEmpty == true)
                            Text(
                              [exp.entreprise, if (exp.lieu?.isNotEmpty == true) exp.lieu]
                                  .join(' — '),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    if (period.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                              fontSize: 10, color: accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                if (exp.actuel) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('En poste',
                        style: TextStyle(
                            fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  ),
                ],
                if (exp.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    exp.description!,
                    style: const TextStyle(fontSize: 11, height: 1.55, color: Color(0xFF4B5563)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formation ─────────────────────────────────────────────────────────────────

class _EducationEntry extends StatelessWidget {
  final Education edu;
  final Color accent;
  const _EducationEntry({required this.edu, required this.accent});

  @override
  Widget build(BuildContext context) {
    final enCours = edu.dateFin == null && edu.dateDebut != null;
    final dateEnd = enCours ? 'En cours' : _fmt(edu.dateFin);
    final period = [_fmt(edu.dateDebut), dateEnd]
        .where((s) => s.isNotEmpty)
        .join(' - ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 10),
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            edu.diplome ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          if (edu.etablissement?.isNotEmpty == true)
                            Text(
                              edu.etablissement!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            ),
                          if (edu.domaine?.isNotEmpty == true)
                            Text(edu.domaine!,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    if (period.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(period,
                            style: TextStyle(
                                fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                if (edu.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(edu.description!,
                      style: const TextStyle(fontSize: 11, height: 1.55, color: Color(0xFF4B5563))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Competences ───────────────────────────────────────────────────────────────

class _SkillsGrid extends StatelessWidget {
  final List<Skill> skills;
  final Color accent;
  const _SkillsGrid({required this.skills, required this.accent});

  List<_SkillData> _splitSkills() {
    final result = <_SkillData>[];
    for (final s in skills) {
      final nom = s.nom ?? '';
      final parts = nom.split(RegExp(r'[,;/]+'));
      for (final p in parts) {
        final trimmed = p.trim();
        if (trimmed.isNotEmpty) {
          result.add(_SkillData(trimmed, s.niveau ?? 3));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final splitSkills = _splitSkills();
    return Column(
      children: splitSkills.map((s) {
        final level = s.niveau.clamp(1, 5);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(s.name,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: level / 5,
                    minHeight: 5,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  _levelLabel(level),
                  style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1: return 'Debutant';
      case 2: return 'Base';
      case 3: return 'Bon';
      case 4: return 'Avance';
      case 5: return 'Expert';
      default: return 'Bon';
    }
  }
}

class _SkillData {
  final String name;
  final int niveau;
  _SkillData(this.name, this.niveau);
}

// ── Langues ───────────────────────────────────────────────────────────────────

class _LanguagesRow extends StatelessWidget {
  final List<Language> languages;
  final Color accent;
  const _LanguagesRow({required this.languages, required this.accent});

  static const _niveauLabels = {
    'A1': 'Debutant',
    'A2': 'Elementaire',
    'B1': 'Intermediaire',
    'B2': 'Avance',
    'C1': 'Courant',
    'C2': 'Bilingue',
    'NATIF': 'Langue maternelle',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: languages.map((l) {
        final label = _niveauLabels[l.niveau] ?? l.niveau ?? '';
        final level = _niveauToLevel(l.niveau);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.langue ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  Text(label,
                      style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: level,
                  minHeight: 4,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _niveauToLevel(String? niveau) {
    switch (niveau) {
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
}

// ── Certifications ────────────────────────────────────────────────────────────

class _CertEntry extends StatelessWidget {
  final Certification cert;
  final Color accent;
  const _CertEntry({required this.cert, required this.accent});

  @override
  Widget build(BuildContext context) {
    final expired = cert.dateExpiration != null &&
        cert.dateExpiration!.isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.nom ?? '',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      if (cert.organisme?.isNotEmpty == true)
                        Text(cert.organisme!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                if (cert.dateObtention != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(cert.dateObtention),
                          style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                      if (expired)
                        const Text('Expire',
                            style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Projets ───────────────────────────────────────────────────────────────────

class _ProjectEntry extends StatelessWidget {
  final Project proj;
  final Color accent;
  const _ProjectEntry({required this.proj, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 10),
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proj.nom ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (proj.technologies?.isNotEmpty == true)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(proj.technologies!,
                        style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                  ),
                if (proj.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(proj.description!,
                      style: const TextStyle(fontSize: 11, height: 1.55, color: Color(0xFF4B5563))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
