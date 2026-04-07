import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<User, NoParams> {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  @override
  Future<Result<User>> call(NoParams params) => _repository.getCurrentUser();
}
