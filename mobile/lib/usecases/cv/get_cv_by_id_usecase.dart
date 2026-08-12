import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../features/cv/presentation/cv_presentation_model.dart';
import '../../repositories/cv_repository.dart';

class GetCvByIdUseCase implements UseCase<Cv, int> {
  final CvRepository _repository;
  const GetCvByIdUseCase(this._repository);

  @override
  Future<Result<Cv>> call(int id) => _repository.getCvById(id);
}
