import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../application/delete_account.dart';
import '../application/export_account_data.dart';

/// Issue d'une action de compte, exposee a la vue (issue #250, E2).
enum AccountActionOutcome { success, failure }

/// Orchestre les actions sensibles du compte (export RGPD, suppression) en
/// separant l'ETAT des EFFETS (issue #250, E2).
///
/// Le controller gere l'etat (en cours, erreur, JSON exporte) et le nettoyage de
/// session apres suppression confirmee. Les effets presse-papier / navigation /
/// snackbar restent a la charge de la vue, a partir de l'[AccountActionOutcome]
/// et des champs exposes — le monolithe melangeait appel reseau, `Clipboard`,
/// `Navigator` et `ScaffoldMessenger` dans le meme widget.
class AccountActionsController extends ChangeNotifier {
  AccountActionsController({
    required ExportAccountDataUseCase exportData,
    required DeleteAccountUseCase deleteAccount,
    required Future<void> Function() clearSession,
  })  : _exportData = exportData,
        _deleteAccount = deleteAccount,
        _clearSession = clearSession;

  final ExportAccountDataUseCase _exportData;
  final DeleteAccountUseCase _deleteAccount;
  final Future<void> Function() _clearSession;

  bool _exporting = false;
  bool get exporting => _exporting;

  bool _deleting = false;
  bool get deleting => _deleting;

  /// Code d'erreur typé de la derniere action (jamais un message brut/stack),
  /// ou null. La vue le traduit en libelle localise.
  String? errorCode;

  /// JSON RGPD pret a copier apres un export reussi (l'effet presse-papier est
  /// realise par la vue), ou null.
  String? exportedJson;

  /// Exporte les donnees. En cas de succes, [exportedJson] contient le JSON a
  /// copier ; la vue realise la copie et la confirmation.
  Future<AccountActionOutcome> exportData() async {
    if (_exporting) return AccountActionOutcome.failure;
    _exporting = true;
    errorCode = null;
    exportedJson = null;
    notifyListeners();

    final result = await _exportData.call();
    _exporting = false;

    switch (result) {
      case Success(:final data):
        exportedJson = data;
        notifyListeners();
        return AccountActionOutcome.success;
      case Failure(:final exception):
        errorCode = exception.code ?? exception.message;
        notifyListeners();
        return AccountActionOutcome.failure;
    }
  }

  /// Supprime le compte. Le nettoyage de session (tokens/cache) n'a lieu QU'APRES
  /// confirmation backend ; un echec laisse la session intacte. La redirection
  /// est faite par la vue sur un [AccountActionOutcome.success].
  Future<AccountActionOutcome> deleteAccount() async {
    if (_deleting) return AccountActionOutcome.failure;
    _deleting = true;
    errorCode = null;
    notifyListeners();

    final result = await _deleteAccount.call();
    _deleting = false;

    switch (result) {
      case Success():
        await _clearSession();
        notifyListeners();
        return AccountActionOutcome.success;
      case Failure(:final exception):
        errorCode = exception.code ?? exception.message;
        notifyListeners();
        return AccountActionOutcome.failure;
    }
  }
}
