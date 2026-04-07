import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class UpdateProfileParams {
  final String? nom;
  final String? prenom;
  const UpdateProfileParams({this.nom, this.prenom});
}

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository _repository;
  const UpdateProfileUseCase(this._repository);

  @override
  Future<Result<User>> call(UpdateProfileParams params) =>
      _repository.updateProfile(nom: params.nom, prenom: params.prenom);
}
