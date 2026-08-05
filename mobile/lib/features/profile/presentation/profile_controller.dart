import '../application/get_profile_dashboard.dart';

/// Vue-modele de l'ecran profil (issue #250, E3).
///
/// Presenteur immuable : derive l'entete (nom, email, initiales) et le
/// [ProfileDashboard] a partir des donnees fournies. Aucune dependance Flutter
/// ni l10n — le repli d'affichage du nom reste a la charge de la vue. Sort du
/// widget la logique d'initiales et le calcul des statistiques.
class ProfileController {
  const ProfileController({
    this.fullName,
    this.email = '',
    required this.dashboard,
  });

  /// Construit le presenteur a partir de l'utilisateur courant et du nombre de
  /// CV. Les compteurs telechargements/partages restent optionnels (backend).
  factory ProfileController.from({
    String? fullName,
    String? email,
    required int cvCount,
    int? downloads,
    int? shares,
    GetProfileDashboard getDashboard = const GetProfileDashboard(),
  }) =>
      ProfileController(
        fullName: fullName,
        email: email ?? '',
        dashboard: getDashboard(
          cvCount: cvCount,
          downloads: downloads,
          shares: shares,
        ),
      );

  final String? fullName;
  final String email;
  final ProfileDashboard dashboard;

  /// Initiales (1-2 lettres majuscules) pour l'avatar, ou « ? » si inconnu.
  String get initials => initialsOf(fullName);

  /// Extrait les initiales d'un nom. Robuste aux espaces multiples / superflus
  /// (le monolithe faisait `split(' ')` et plantait sur « Jean  Dupont »).
  static String initialsOf(String? name) {
    if (name == null) return '?';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
