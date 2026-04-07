import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/cv.dart';
import '../../repositories/cv_repository.dart';

class DuplicateCvUseCase implements UseCase<Cv, int> {
  final CvRepository _repository;
  const DuplicateCvUseCase(this._repository);

  @override
  Future<Result<Cv>> call(int id) => _repository.duplicateCv(id);
}
