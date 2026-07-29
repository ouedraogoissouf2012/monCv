import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../usecases/cv/get_all_cvs_usecase.dart';
import '../../application/state/cv_operation_state.dart';
import '../cv_store.dart';

/// Charge la liste des CV dans le [CvStore] (issue #240).
///
/// Orchestre le use case [GetAllCvsUseCase] puis applique le resultat au store.
/// Ne detient aucun etat : la liste vit dans le store partage.
class CvListController {
  final GetAllCvsUseCase _getAllCvs;
  final CvStore _store;

  CvListController({
    required GetAllCvsUseCase getAllCvs,
    required CvStore store,
  })  : _getAllCvs = getAllCvs,
        _store = store;

  Future<void> load() async {
    _store.setState(const CvOperationState.loading());
    final result = await _getAllCvs(const NoParams());
    switch (result) {
      case Success(:final data):
        _store.setCvs(data);
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
    }
  }
}
