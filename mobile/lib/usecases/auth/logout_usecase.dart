import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}
