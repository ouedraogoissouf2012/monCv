import '../../../../core/error/result.dart';
import '../../../../models/cv_style.dart';
import '../../../../repositories/cv_repository.dart';
import '../../application/state/cv_operation_state.dart';
import '../cv_store.dart';

/// Applique un changement de style a un CV et le persiste (issue #240).
///
/// Optimiste : met a jour le store immediatement, puis persiste. En cas
/// d'echec, l'etat passe en [CvOperationState.failure] ET le store revient au
/// CV original : aucun autre ecran ne doit afficher un style non persiste
/// comme s'il etait sauvegarde.
class CvStyleController {
  final CvRepository _repository;
  final CvStore _store;

  CvStyleController({
    required CvRepository repository,
    required CvStore store,
  })  : _repository = repository,
        _store = store;

  Future<bool> update(int cvId, CvStyle style) async {
    final cv = _store.currentCv?.id == cvId
        ? _store.currentCv
        : _store.cvs.where((c) => c.id == cvId).firstOrNull;

    if (cv == null) {
      _store.setState(const CvOperationState.failure('CV introuvable'));
      return false;
    }

    final optimistic = cv.copyWith(style: style);
    _store.replaceCv(cvId, optimistic);

    final result = await _repository.updateCv(cvId, optimistic);
    switch (result) {
      case Success(:final data):
        _store.replaceCv(cvId, data);
        return true;
      case Failure(:final exception):
        _store.replaceCv(cvId, cv);
        _store.setState(CvOperationState.failure(exception.message));
        return false;
    }
  }
}
