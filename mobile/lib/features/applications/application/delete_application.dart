import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/application_repository.dart';

/// Supprime une candidature par son identifiant — issue #246, A2.
class DeleteApplicationUseCase implements UseCase<void, int> {
  const DeleteApplicationUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  Future<Result<void>> call(int id) => _repository.delete(id);
}
