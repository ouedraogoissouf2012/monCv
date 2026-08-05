/// Port du compte utilisateur (issue #250, E2).
///
/// Abstrait les operations sensibles du compte (export RGPD, suppression
/// definitive) pour que la presentation n'accede jamais au transport reseau
/// directement — le monolithe `profile_screen.dart` appelait `IApiClient`
/// depuis le widget. L'implementation vit dans `data/`.
abstract interface class AccountRepository {
  /// Recupere l'ensemble des donnees personnelles de l'utilisateur (RGPD).
  Future<Map<String, dynamic>> exportData();

  /// Supprime definitivement le compte cote backend. Ne touche pas la session
  /// locale : le nettoyage tokens/cache est orchestre apres confirmation.
  Future<void> deleteAccount();
}
