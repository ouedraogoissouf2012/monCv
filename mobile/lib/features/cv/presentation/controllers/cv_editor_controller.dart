import '../../../../core/error/result.dart';
import '../../../../models/cv.dart';
import '../../../../repositories/cv_repository.dart';
import '../../../../services/sync_queue.dart';
import '../../../../usecases/cv/create_cv_usecase.dart';
import '../../../../usecases/cv/update_cv_usecase.dart';
import '../../../../usecases/cv/delete_cv_usecase.dart';
import '../../../../usecases/cv/duplicate_cv_usecase.dart';
import '../../../../usecases/cv/create_variant_usecase.dart';
import '../../application/apply_ai_enhancements.dart';
import '../../application/state/cv_operation_state.dart';
import '../../data/cv_cache_codec.dart';
import '../cv_store.dart';

/// Ecritures sur les CV (create/update/delete/duplicate/variant, style IA)
/// appliquees au [CvStore] partage (issue #240).
///
/// Quand l'appareil est hors ligne, create/update sont mis en file d'attente
/// ([SyncQueue]) avec un id temporaire negatif ; l'etat passe en pendingSync.
class CvEditorController {
  final CreateCvUseCase _createCv;
  final UpdateCvUseCase _updateCv;
  final DeleteCvUseCase _deleteCv;
  final DuplicateCvUseCase _duplicateCv;
  final CreateVariantUseCase _createVariant;
  final CvRepository _repository;
  final SyncQueue? _syncQueue;
  final CvStore _store;
  final ApplyAiEnhancements _applyAi = const ApplyAiEnhancements();

  int _tempIdCounter = -1;

  CvEditorController({
    required CreateCvUseCase createCv,
    required UpdateCvUseCase updateCv,
    required DeleteCvUseCase deleteCv,
    required DuplicateCvUseCase duplicateCv,
    required CreateVariantUseCase createVariant,
    required CvRepository repository,
    required CvStore store,
    SyncQueue? syncQueue,
  })  : _createCv = createCv,
        _updateCv = updateCv,
        _deleteCv = deleteCv,
        _duplicateCv = duplicateCv,
        _createVariant = createVariant,
        _repository = repository,
        _store = store,
        _syncQueue = syncQueue;

  int get _pendingCount => _syncQueue?.pendingCount ?? 0;

  Future<bool> create(Cv cv) async {
    _store.setState(const CvOperationState.loading());

    if (_store.isOffline && _syncQueue != null) {
      final tempId = _tempIdCounter--;
      final offlineCv = cv.copyWith(id: tempId);
      _store.addCv(offlineCv, makeCurrent: true);
      await _syncQueue!.add(PendingOperation(
        id: 'create_$tempId',
        type: 'create',
        cvJson: cvToQueueString(cv),
        cvId: tempId,
        createdAt: DateTime.now(),
      ));
      _store.setState(CvOperationState.pendingSync(_pendingCount));
      return true;
    }

    final result = await _createCv(cv);
    switch (result) {
      case Success(:final data):
        _store.addCv(data, makeCurrent: true);
        _store.setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> update(int id, Cv cv) async {
    _store.setState(const CvOperationState.loading());

    if (_store.isOffline && _syncQueue != null) {
      _store.replaceCv(id, cv);
      await _syncQueue!.add(PendingOperation(
        id: 'update_${id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'update',
        cvJson: cvToQueueString(cv),
        cvId: id,
        createdAt: DateTime.now(),
      ));
      _store.setState(CvOperationState.pendingSync(_pendingCount));
      return true;
    }

    final result = await _updateCv(UpdateCvParams(id: id, cv: cv));
    switch (result) {
      case Success(:final data):
        _store.replaceCv(id, data);
        _store.setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> delete(int id) async {
    _store.setState(const CvOperationState.loading());
    final result = await _deleteCv(id);
    switch (result) {
      case Success():
        _store.removeCv(id);
        _store.setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> duplicate(int id) async {
    _store.setState(const CvOperationState.loading());
    final result = await _duplicateCv(id);
    switch (result) {
      case Success(:final data):
        _store.addCv(data);
        _store.setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<Cv?> createVariant(int cvId, String jobDescription,
      {String? label}) async {
    _store.setState(const CvOperationState.loading());
    final result = await _createVariant(CreateVariantParams(
      cvId: cvId,
      jobDescription: jobDescription,
      label: label,
    ));
    switch (result) {
      case Success(:final data):
        _store.addCv(data);
        _store.setState(const CvOperationState.success());
        return data;
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
        return null;
    }
  }

  Future<bool> applyAiEnhancements(int cvId, Map<String, dynamic> result) async {
    final cv = _store.currentCv;
    if (cv == null || cv.id != cvId) return false;

    final updatedCv = _applyAi(cv, result);
    _store.replaceCv(cvId, updatedCv);
    _store.setCurrentCv(updatedCv);

    // Persistance best-effort ; propagation du resultat en PR offline.
    await _repository.updateCv(cvId, updatedCv);
    return true;
  }
}
