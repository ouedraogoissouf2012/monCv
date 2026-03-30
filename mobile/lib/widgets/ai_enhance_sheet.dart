import 'package:flutter/material.dart';
import '../models/cv.dart';
import '../services/api_service.dart';

/// Bottom sheet d'amelioration IA — 3 niveaux : Lite / Medium / Max
/// Retourne le resultat via Navigator.pop (pas de callback)
class AiEnhanceSheet extends StatefulWidget {
  final Cv cv;

  const AiEnhanceSheet({super.key, required this.cv});

  @override
  State<AiEnhanceSheet> createState() => _AiEnhanceSheetState();
}

class _AiEnhanceSheetState extends State<AiEnhanceSheet> {
  String _selectedLevel = 'MEDIUM';
  bool _loading = false;
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

  Future<void> _enhance() async {
    if (widget.cv.id == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ApiService().enhanceCv(widget.cv.id!, _selectedLevel);
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
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 10),
                Text('Ameliorer avec l\'IA',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choisissez le niveau d\'amelioration souhaite',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 20),

            // Selecteur de niveau
            if (_result == null) ...[
              ..._levels.map((lvl) => _LevelTile(
                    info: lvl,
                    selected: _selectedLevel == lvl.id,
                    onTap: () => setState(() => _selectedLevel = lvl.id),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _enhance,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_loading ? 'Amelioration en cours...' : 'Ameliorer'),
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
              _ResultSection(result: _result!, cv: widget.cv),
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
            color:
                selected ? info.color : colorScheme.outline.withValues(alpha: 0.25),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.55))),
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

  const _ResultSection({required this.result, required this.cv});

  @override
  Widget build(BuildContext context) {
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
              color: aiGenerated
                  ? const Color(0xFF10B981)
                  : colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              aiGenerated
                  ? 'Amelioration generee'
                  : 'Mode hors ligne - cle DeepSeek manquante',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: aiGenerated
                    ? const Color(0xFF10B981)
                    : colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Titre du poste
        if (result['titrePoste'] != null && (result['titrePoste'] as String).isNotEmpty) ...[
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
        if (result['educations'] != null && (result['educations'] as List).isNotEmpty) ...[
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
        if (result['skills'] != null && (result['skills'] as List).isNotEmpty) ...[
          _sectionLabel(context, 'Competences'),
          _BeforeAfter(
            before: cv.skills.map((s) => s.nom ?? '').join(', '),
            after: (result['skills'] as List<dynamic>).map((s) => s['nom'] as String? ?? '').join(', '),
          ),
          const SizedBox(height: 10),
        ],

        // Projets
        if (result['projects'] != null && (result['projects'] as List).isNotEmpty) ...[
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
                          color: colorScheme.onSurface.withValues(alpha: 0.45))),
                  const SizedBox(height: 2),
                  Text(before,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.6),
                          decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
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
                Text(after,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
