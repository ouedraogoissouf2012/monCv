/// Un point d'historique de score ATS (issue #245).
///
/// Modele pur, localise-agnostique : porte [isRerun] (premiere analyse vs
/// re-analyse) plutot qu'un libelle traduit ; la presentation choisit le texte.
/// [createdAt] est injecte (le domaine ne lit pas l'horloge) pour rester
/// testable de facon deterministe.
class JobScoreSnapshot {
  const JobScoreSnapshot({
    required this.score,
    required this.createdAt,
    required this.isRerun,
  });

  final int score;
  final DateTime createdAt;
  final bool isRerun;

  @override
  bool operator ==(Object other) =>
      other is JobScoreSnapshot &&
      other.score == score &&
      other.createdAt == createdAt &&
      other.isRerun == isRerun;

  @override
  int get hashCode => Object.hash(score, createdAt, isRerun);
}

/// Historique borne des scores ATS pour une session (issue #245).
///
/// Session-only par decision explicite (comme le monolithe : aucune
/// persistance). Les entrees les plus recentes en tete ; la taille est bornee
/// a [maxEntries] (defaut 4) — les plus anciennes sont evincees.
class JobScoreHistory {
  JobScoreHistory({this.maxEntries = 4}) : assert(maxEntries > 0);

  final int maxEntries;
  final List<JobScoreSnapshot> _entries = [];

  /// Entrees, de la plus recente a la plus ancienne (lecture seule).
  List<JobScoreSnapshot> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;
  int get length => _entries.length;

  /// Ajoute un score en tete. [isRerun] est vrai si l'historique n'etait pas
  /// vide (donc une re-analyse). Eviction des plus anciennes au-dela de
  /// [maxEntries].
  void record(int score, DateTime at) {
    _entries.insert(
      0,
      JobScoreSnapshot(score: score, createdAt: at, isRerun: _entries.isNotEmpty),
    );
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }
}
