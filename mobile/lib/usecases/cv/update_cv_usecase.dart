import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/cv.dart';
import '../../repositories/cv_repository.dart';

class UpdateCvParams {
  final int id;
  final Cv cv;
  const UpdateCvParams({required this.id, required this.cv});
}

class UpdateCvUseCase implements UseCase<Cv, UpdateCvParams> {
  final CvRepository _repository;
  const UpdateCvUseCase(this._repository);

  @override
  Future<Result<Cv>> call(UpdateCvParams params) =>
      _repository.updateCv(params.id, params.cv);
}
