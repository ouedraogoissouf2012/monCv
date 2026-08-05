import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../domain/account_repository.dart';

/// Supprime definitivement le compte utilisateur cote backend (issue #250, E2).
///
/// Retourne un [Result] typé : le nettoyage de session (tokens/cache) et la
/// redirection ne doivent avoir lieu qu'apres un `Success` — un echec laisse la
/// session intacte. Le monolithe supprimait puis deconnectait sans distinguer
/// l'echec backend.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<void>> call() =>
      safeCall(() => _repository.deleteAccount());
}
