/// Statistiques du tableau de bord profil (issue #250, E3).
///
/// Vue-modele pur (aucune dependance Flutter). Les compteurs telechargements /
/// partages ne sont PAS encore fournis par le backend : exposes a `null` et
/// affiches comme [unknown] (« — ») — jamais inventes. Le monolithe codait ces
/// « — » en dur dans le widget.
class ProfileDashboard {
  const ProfileDashboard({
    required this.cvCount,
    this.downloads,
    this.shares,
  });

  final int cvCount;
  final int? downloads;
  final int? shares;

  /// Marqueur d'une statistique inconnue (non encore disponible).
  static const String unknown = '—';

  String get cvCountLabel => '$cvCount';
  String get downloadsLabel => _label(downloads);
  String get sharesLabel => _label(shares);

  static String _label(int? value) => value?.toString() ?? unknown;
}

/// Calcule le [ProfileDashboard] a partir des donnees disponibles (issue #250).
///
/// Sortir le calcul du widget permet de le tester et d'ajouter les compteurs
/// backend sans toucher a la presentation.
class GetProfileDashboard {
  const GetProfileDashboard();

  ProfileDashboard call({
    required int cvCount,
    int? downloads,
    int? shares,
  }) =>
      ProfileDashboard(
        cvCount: cvCount,
        downloads: downloads,
        shares: shares,
      );
}
