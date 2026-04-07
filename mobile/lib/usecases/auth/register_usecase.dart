import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String? nom;
  final String? prenom;
  const RegisterParams({
    required this.email,
    required this.password,
    this.nom,
    this.prenom,
  });
}

class RegisterUseCase implements UseCase<AuthResponse, RegisterParams> {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  @override
  Future<Result<AuthResponse>> call(RegisterParams params) =>
      _repository.register(
        email: params.email,
        password: params.password,
        nom: params.nom,
        prenom: params.prenom,
      );
}
