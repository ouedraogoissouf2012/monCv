import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/password_reset_repository.dart';

/// Parametres de la demande de reinitialisation (issue #381).
class RequestPasswordResetParams {
  final String email;
  const RequestPasswordResetParams({required this.email});
}

/// Demande un lien de reinitialisation (issue #381).
///
/// Delegation stricte au port [PasswordResetRepository] (qui renvoie deja un
/// [Result] typé). La reponse serveur est uniforme que l'email existe ou non
/// (anti-enumeration).
class RequestPasswordResetUseCase
    implements UseCase<void, RequestPasswordResetParams> {
  final PasswordResetRepository _repository;
  const RequestPasswordResetUseCase(this._repository);

  @override
  Future<Result<void>> call(RequestPasswordResetParams params) =>
      _repository.requestReset(params.email);
}
