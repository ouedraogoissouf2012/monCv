import '../../../../core/error/result.dart';
import '../../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../../usecases/cv/get_cv_by_id_usecase.dart';
import '../../application/state/cv_operation_state.dart';
import '../cv_store.dart';

/// Charge un CV par son id et gere le CV courant dans le [CvStore] (issue #240).
class CvDetailController {
  final GetCvByIdUseCase _getCvById;
  final CvStore _store;

  CvDetailController({
    required GetCvByIdUseCase getCvById,
    required CvStore store,
  })  : _getCvById = getCvById,
        _store = store;

  Future<void> load(int id) async {
    _store.setState(const CvOperationState.loading());
    final result = await _getCvById(id);
    switch (result) {
      case Success(:final data):
        _store.setCurrentCv(data);
        _store.setState(const CvOperationState.success());
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
    }
  }

  void select(Cv? cv) => _store.setCurrentCv(cv);
}
