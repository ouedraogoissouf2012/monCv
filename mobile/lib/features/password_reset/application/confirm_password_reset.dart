import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/password_reset_repository.dart';

/// Parametres de la reinitialisation effective (issue #381).
class ConfirmPasswordResetParams {
  final String token;
  final String newPassword;
  const ConfirmPasswordResetParams({
    required this.token,
    required this.newPassword,
  });
}

/// Definit le nouveau mot de passe a partir d'un jeton (issue #381).
///
/// Delegation stricte au port [PasswordResetRepository]. Un jeton inconnu,
/// expire ou deja utilise donne un [Result] en echec (le serveur repond 400).
class ConfirmPasswordResetUseCase
    implements UseCase<void, ConfirmPasswordResetParams> {
  final PasswordResetRepository _repository;
  const ConfirmPasswordResetUseCase(this._repository);

  @override
  Future<Result<void>> call(ConfirmPasswordResetParams params) =>
      _repository.confirmReset(
        token: params.token,
        newPassword: params.newPassword,
      );
}
