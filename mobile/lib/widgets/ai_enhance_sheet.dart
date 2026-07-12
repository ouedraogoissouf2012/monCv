import 'package:flutter/material.dart';
import '../models/cv.dart';
import '../services/api_service.dart';

/// Bottom sheet d'amelioration IA — 3 niveaux : Lite / Medium / Max
/// Retourne le resultat via Navigator.pop (pas de callback)
class AiEnhanceSheet extends StatefulWidget {
  final Cv cv;
  final String initialLevel;
  final bool proofreadOnly;

  const AiEnhanceSheet({
    super.key,
    required this.cv,
    this.initialLevel = 'MEDIUM',
    this.proofreadOnly = false,
  });

  @override
  State<AiEnhanceSheet> createState() => _AiEnhanceSheetState();
}

class _AiEnhanceSheetState extends State<AiEnhanceSheet> {
  late String _selectedLevel;
  bool _loading = false;
  bool _aiConsentAccepted = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const _levels = [
    _LevelInfo(
      id: 'LITE',
      label: 'Lite',
      description: 'Correction orthographe & grammaire uniquement',
      icon: Icons.spellcheck_rounded,
      color: Color(0xFF10B981),
    ),
    _LevelInfo(
      id: 'MEDIUM',
      label: 'Medium',
      description: 'Lite + reformulation pour plus d\'impact',
      icon: Icons.auto_fix_normal_rounded,
      color: Color(0xFF2563EB),
    ),
    _LevelInfo(
      id: 'MAX',
      label: 'Max',
      description: 'Restructuration complete, mots-cles ATS, verbes d\'action',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.proofreadOnly ? 'LITE' : widget.initialLevel;
  }

  Future<void> _enhance() async {
    if (widget.cv.id == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result =
          await ApiService().enhanceCv(widget.cv.id!, _selectedLevel);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignee
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.proofreadOnly
                        ? Icons.spellcheck_rounded
                        : Icons.auto_awesome_rounded,
                    color: widget.proofreadOnly
                        ? const Color(0xFF10B981)
                        : const Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                    widget.proofreadOnly
                        ? 'Correction orthographique'
                        : 'Améliorer avec l\'IA',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.proofreadOnly
                  ? 'Relisez tout le CV sans modifier le sens ni inventer de contenu.'
                  : 'Choisissez le niveau d\'amélioration souhaité',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 20),

            // Selecteur de niveau
            if (_result == null) ...[
              if (widget.proofreadOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Orthographe, grammaire, accents et termes professionnels. Les niveaux et les faits restent inchangés.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                )
              else
                ..._levels.map((lvl) => _LevelTile(
                      info: lvl,
                      selected: _selectedLevel == lvl.id,
                      onTap: () => setState(() => _selectedLevel = lvl.id),
                    )),
              const SizedBox(height: 16),
              _AiConsentNotice(
                value: _aiConsentAccepted,
                onChanged: (value) => setState(() {
                  _aiConsentAccepted = value ?? false;
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading || !_aiConsentAccepted ? null : _enhance,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(widget.proofreadOnly
                          ? Icons.spellcheck_rounded
                          : Icons.auto_awesome_rounded),
                  label: Text(_loading
                      ? 'Relecture en cours...'
                      : widget.proofreadOnly
                          ? 'Relire le CV'
                          : 'Améliorer'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Resultat
              _ResultSection(
                result: _result!,
                cv: widget.cv,
                proofreadOnly: widget.proofreadOnly,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _result = null),
                      child: const Text('Reessayer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // print('[AI-SHEET] Appliquer pressed! result keys: ${_result?.keys}');
                        Navigator.of(context).pop(_result);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Appliquer'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiConsentNotice extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AiConsentNotice({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'J\'accepte que le contenu de ce CV soit envoyé au service IA pour générer des corrections ou suggestions. Les changements restent à valider avant application.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile niveau ──────────────────────────────────────────────────

class _LevelInfo {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _LevelInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _LevelTile extends StatelessWidget {
  final _LevelInfo info;
  final bool selected;
  final VoidCallback onTap;

  const _LevelTile(
      {required this.info, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? info.color
                : colorScheme.outline.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          color: selected ? info.color.withValues(alpha: 0.05) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icon, color: info.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected ? info.color : null)),
                  const SizedBox(height: 2),
                  Text(info.description,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: info.color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Resultat avant/apres ────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final Map<String, dynamic> result;
  final Cv cv;
  final bool proofreadOnly;

  const _ResultSection({
    required this.result,
    required this.cv,
    required this.proofreadOnly,
  });

  @override
  Widget build(BuildContext context) {
    if (proofreadOnly) {
      return _ProofreadingResult(result: result, cv: cv);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final aiGenerated = result['aiGenerated'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              aiGenerated
                  ? Icons.auto_awesome_rounded
                  : Icons.warning_amber_rounded,
              size: 16,
              color: aiGenerated ? const Color(0xFF10B981) : colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              aiGenerated
                  ? 'Amelioration generee'
                  : 'Mode hors ligne - cle DeepSeek manquante',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    aiGenerated ? const Color(0xFF10B981) : colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Titre du poste
        if (result['titrePoste'] != null &&
            (result['titrePoste'] as String).isNotEmpty) ...[
          _sectionLabel(context, 'Titre du poste'),
          _BeforeAfter(
            before: cv.personalInfo?.titrePoste ?? '',
            after: result['titrePoste'] as String,
          ),
          const SizedBox(height: 10),
        ],

        // Resume professionnel
        if (result['resumeProfessionnel'] != null) ...[
          _sectionLabel(context, 'Resume professionnel'),
          _BeforeAfter(
            before: cv.personalInfo?.resumeProfessionnel ?? '',
            after: result['resumeProfessionnel'] as String,
          ),
          const SizedBox(height: 10),
        ],

        // Experiences
        if (result['experiences'] != null) ...[
          _sectionLabel(context, 'Experiences'),
          ...List.generate(
            (result['experiences'] as List<dynamic>).length,
            (i) {
              final e = (result['experiences'] as List<dynamic>)[i];
              final enhanced = e['description'] as String? ?? '';
              final original = i < cv.experiences.length
                  ? cv.experiences[i].description ?? ''
                  : '';
              return _BeforeAfter(before: original, after: enhanced);
            },
          ),
          const SizedBox(height: 10),
        ],

        // Formations
        if (result['educations'] != null &&
            (result['educations'] as List).isNotEmpty) ...[
          _sectionLabel(context, 'Formations'),
          ...List.generate(
            (result['educations'] as List<dynamic>).length,
            (i) {
              final e = (result['educations'] as List<dynamic>)[i];
              final enhanced = e['description'] as String? ?? '';
              final original = i < cv.educations.length
                  ? cv.educations[i].description ?? ''
                  : '';
              return _BeforeAfter(before: original, after: enhanced);
            },
          ),
          const SizedBox(height: 10),
        ],

        // Competences
        if (result['skills'] != null &&
            (result['skills'] as List).isNotEmpty) ...[
          _sectionLabel(context, 'Competences'),
          _BeforeAfter(
            before: cv.skills.map((s) => s.nom ?? '').join(', '),
            after: (result['skills'] as List<dynamic>)
                .map((s) => s['nom'] as String? ?? '')
                .join(', '),
          ),
          const SizedBox(height: 10),
        ],

        // Projets
        if (result['projects'] != null &&
            (result['projects'] as List).isNotEmpty) ...[
          _sectionLabel(context, 'Projets'),
          ...List.generate(
            (result['projects'] as List<dynamic>).length,
            (i) {
              final p = (result['projects'] as List<dynamic>)[i];
              final enhanced = p['description'] as String? ?? '';
              final original = i < cv.projects.length
                  ? cv.projects[i].description ?? ''
                  : '';
              return _BeforeAfter(before: original, after: enhanced);
            },
          ),
        ],
      ],
    );
  }
}

class _ProofreadingResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Cv cv;

  const _ProofreadingResult({required this.result, required this.cv});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final changes = <_ReviewChange>[];

    void addChange(String section, String? before, String? after) {
      final original = before ?? '';
      final corrected = after ?? '';
      if (corrected.isNotEmpty && corrected != original) {
        changes.add(_ReviewChange(section, original, corrected));
      }
    }

    List<Map<String, dynamic>> items(String key) {
      final raw = result[key] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    addChange('Titre du poste', cv.personalInfo?.titrePoste,
        result['titrePoste'] as String?);
    addChange('Résumé professionnel', cv.personalInfo?.resumeProfessionnel,
        result['resumeProfessionnel'] as String?);

    final experiences = items('experiences');
    for (int i = 0; i < experiences.length && i < cv.experiences.length; i++) {
      addChange('Expérience ${i + 1} - intitulé', cv.experiences[i].poste,
          experiences[i]['poste'] as String?);
      addChange(
          'Expérience ${i + 1} - description',
          cv.experiences[i].description,
          experiences[i]['description'] as String?);
    }

    final educations = items('educations');
    for (int i = 0; i < educations.length && i < cv.educations.length; i++) {
      addChange(
          'Formation ${i + 1} - établissement',
          cv.educations[i].etablissement,
          educations[i]['etablissement'] as String?);
      addChange('Formation ${i + 1} - diplôme', cv.educations[i].diplome,
          educations[i]['diplome'] as String?);
      addChange('Formation ${i + 1} - domaine', cv.educations[i].domaine,
          educations[i]['domaine'] as String?);
      addChange(
          'Formation ${i + 1} - description',
          cv.educations[i].description,
          educations[i]['description'] as String?);
    }

    final skills = items('skills');
    for (int i = 0; i < skills.length && i < cv.skills.length; i++) {
      addChange(
          'Compétence ${i + 1}', cv.skills[i].nom, skills[i]['nom'] as String?);
    }

    final languages = items('languages');
    for (int i = 0; i < languages.length && i < cv.languages.length; i++) {
      addChange('Langue ${i + 1}', cv.languages[i].langue,
          languages[i]['langue'] as String?);
    }

    final certifications = items('certifications');
    for (int i = 0;
        i < certifications.length && i < cv.certifications.length;
        i++) {
      addChange('Certification ${i + 1}', cv.certifications[i].nom,
          certifications[i]['nom'] as String?);
      addChange(
          'Certification ${i + 1} - organisme',
          cv.certifications[i].organisme,
          certifications[i]['organisme'] as String?);
    }

    final projects = items('projects');
    for (int i = 0; i < projects.length && i < cv.projects.length; i++) {
      addChange('Projet ${i + 1} - nom', cv.projects[i].nom,
          projects[i]['nom'] as String?);
      addChange('Projet ${i + 1} - technologies', cv.projects[i].technologies,
          projects[i]['technologies'] as String?);
      addChange('Projet ${i + 1} - description', cv.projects[i].description,
          projects[i]['description'] as String?);
    }

    final correctionCount =
        (result['correctionCount'] as num?)?.toInt() ?? changes.length;
    final warnings = (result['warnings'] as List<dynamic>? ?? const [])
        .map((warning) => warning.toString())
        .where((warning) => warning.isNotEmpty)
        .toList();
    final aiGenerated = result['aiGenerated'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.spellcheck_rounded,
                  color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aiGenerated
                          ? 'Relecture IA terminée'
                          : 'Relecture locale terminée',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      correctionCount == 0
                          ? 'Aucune correction certaine détectée.'
                          : '$correctionCount champ${correctionCount > 1 ? 's' : ''} corrigé${correctionCount > 1 ? 's' : ''}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (changes.isEmpty)
          Text(
            'Le texte peut être appliqué sans changement.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          ...changes.expand((change) => [
                _sectionLabel(context, change.section),
                _BeforeAfter(before: change.before, after: change.after),
                const SizedBox(height: 2),
              ]),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Points à préciser',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: warnings
                  .map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(warning,
                                  style: const TextStyle(
                                      fontSize: 12, height: 1.35)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewChange {
  final String section;
  final String before;
  final String after;

  const _ReviewChange(this.section, this.before, this.after);
}

Widget _sectionLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700)),
  );
}

class _BeforeAfter extends StatelessWidget {
  final String before;
  final String after;

  const _BeforeAfter({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (before.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avant',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.45))),
                  const SizedBox(height: 2),
                  Text(before,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
          Divider(
              height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apres',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981))),
                const SizedBox(height: 2),
                Text(after, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
