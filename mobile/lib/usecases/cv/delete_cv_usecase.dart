import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../repositories/cv_repository.dart';

class DeleteCvUseCase implements UseCase<void, int> {
  final CvRepository _repository;
  const DeleteCvUseCase(this._repository);

  @override
  Future<Result<void>> call(int id) => _repository.deleteCv(id);
}
