import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<AuthResponse, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<Result<AuthResponse>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}
