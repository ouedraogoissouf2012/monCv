import '../../core/error/result.dart';
import '../../core/usecase/usecase.dart';
import '../../models/cv.dart';
import '../../repositories/cv_repository.dart';

class GetAllCvsUseCase implements UseCase<List<Cv>, NoParams> {
  final CvRepository _repository;
  const GetAllCvsUseCase(this._repository);

  @override
  Future<Result<List<Cv>>> call(NoParams params) => _repository.getAllCvs();
}
