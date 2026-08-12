import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../features/cv/presentation/cv_presentation_model.dart';
import '../../repositories/cv_repository.dart';

class CreateCvUseCase implements UseCase<Cv, Cv> {
  final CvRepository _repository;
  const CreateCvUseCase(this._repository);

  @override
  Future<Result<Cv>> call(Cv cv) => _repository.createCv(cv);
}
