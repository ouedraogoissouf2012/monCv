import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/cv.dart';
import '../../repositories/cv_repository.dart';

class CreateVariantParams {
  final int cvId;
  final String jobDescription;
  final String? label;
  const CreateVariantParams({required this.cvId, required this.jobDescription, this.label});
}

class CreateVariantUseCase implements UseCase<Cv, CreateVariantParams> {
  final CvRepository _repository;
  const CreateVariantUseCase(this._repository);

  @override
  Future<Result<Cv>> call(CreateVariantParams params) =>
      _repository.createVariant(params.cvId, params.jobDescription, label: params.label);
}
