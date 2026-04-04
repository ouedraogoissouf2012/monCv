import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Bottom sheet pour analyser la correspondance CV / offre d'emploi.
class JobMatchSheet extends StatefulWidget {
  final int cvId;
  const JobMatchSheet({super.key, required this.cvId});

  @override
  State<JobMatchSheet> createState() => _JobMatchSheetState();
}

class _JobMatchSheetState extends State<JobMatchSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _creatingVariant = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _createVariant() async {
    setState(() => _creatingVariant = true);
    try {
      final adapted = await ApiService().adaptCvToJob(widget.cvId, _controller.text.trim());
      if (!mounted) return;
      Navigator.pop(context, adapted); // Retourne le resultat au parent
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating));
      setState(() => _creatingVariant = false);
    }
  }

  Future<void> _analyze() async {
    if (_controller.text.trim().length < 20) {
      setState(() => _error = 'Collez le texte complet de l\'offre (min 20 caracteres)');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await ApiService().matchJob(widget.cvId, _controller.text.trim());
      if (!mounted) return;
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header
            Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.work_outline_rounded, color: Color(0xFF2563EB), size: 20)),
              const SizedBox(width: 10),
              Text('Adapter a une offre',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text('Collez le texte d\'une offre d\'emploi pour analyser la correspondance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 16),

            if (_result == null) ...[
              // Input
              TextFormField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Collez ici le texte de l\'offre d\'emploi...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _analyze,
                  icon: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics_outlined),
                  label: Text(_loading ? 'Analyse en cours...' : 'Analyser la correspondance'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                )),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
              ],
            ] else ...[
              // Score
              _ScoreCard(score: _result!['score'] as int? ?? 0),
              const SizedBox(height: 16),

              // Mots-cles presents
              if (_result!['matchedKeywords'] != null &&
                  (_result!['matchedKeywords'] as List).isNotEmpty) ...[
                _KeywordSection(
                  title: 'Mots-cles presents',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  keywords: List<String>.from(_result!['matchedKeywords']),
                ),
                const SizedBox(height: 12),
              ],

              // Mots-cles manquants
              if (_result!['missingKeywords'] != null &&
                  (_result!['missingKeywords'] as List).isNotEmpty) ...[
                _KeywordSection(
                  title: 'Mots-cles manquants',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFEF4444),
                  keywords: List<String>.from(_result!['missingKeywords']),
                ),
                const SizedBox(height: 12),
              ],

              // Suggestions
              if (_result!['suggestions'] != null &&
                  (_result!['suggestions'] as List).isNotEmpty) ...[
                Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                    color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                ...List<String>.from(_result!['suggestions']).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('  →  ', style: TextStyle(color: Color(0xFF2563EB))),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                  ]),
                )),
                const SizedBox(height: 12),
              ],

              // Bouton creer variante
              const SizedBox(height: 4),
              SizedBox(width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _creatingVariant ? null : _createVariant,
                  icon: _creatingVariant
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.content_copy_rounded, size: 18),
                  label: Text(_creatingVariant ? 'Creation...' : 'Creer une variante adaptee'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
              const SizedBox(height: 8),
              // Bouton re-analyser
              SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Analyser une autre offre'),
                )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? const Color(0xFF10B981)
        : score >= 40 ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final label = score >= 70 ? 'Bon match' : score >= 40 ? 'Match moyen' : 'Faible match';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        SizedBox(width: 60, height: 60,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100, strokeWidth: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color)),
            Text('$score%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ])),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text('Score de correspondance avec l\'offre',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        ])),
      ]),
    );
  }
}

class _KeywordSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  const _KeywordSection({required this.title, required this.icon, required this.color, required this.keywords});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6,
        children: keywords.map((k) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(k, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        )).toList()),
    ]);
  }
}
