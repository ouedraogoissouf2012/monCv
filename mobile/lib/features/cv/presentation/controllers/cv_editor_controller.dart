import '../../../../core/error/result.dart';
import '../../../../repositories/cv_repository.dart';
import '../../../../services/sync_queue.dart';
import '../../../../usecases/cv/create_cv_usecase.dart';
import '../../../../usecases/cv/update_cv_usecase.dart';
import '../../../../usecases/cv/delete_cv_usecase.dart';
import '../../../../usecases/cv/duplicate_cv_usecase.dart';
import '../../../../usecases/cv/create_variant_usecase.dart';
import '../../../ai/domain/entities/enhanced_cv.dart';
import '../../application/apply_ai_enhancements.dart';
import '../../application/state/cv_operation_state.dart';
import '../../data/cv_cache_codec.dart';
import '../cv_presentation_model.dart';
import '../cv_store.dart';
import '../cv_writer.dart';

/// Ecritures sur les CV (create/update/delete/duplicate/variant, style IA)
/// appliquees au [CvStore] partage (issue #240).
///
/// Quand l'appareil est hors ligne, create/update sont mis en file d'attente
/// ([SyncQueue]) avec un id temporaire negatif ; l'etat passe en pendingSync.
///
/// Implementation de production du port [CvWriter] (issue #501) : c'est la
/// seule voie par laquelle l'UI ecrit un CV, ce qui garantit que la liste et le
/// CV courant restent alignes sur la version persistee sans rechargement.
class CvEditorController implements CvWriter {
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

  @override
  Future<Result<Cv>> create(Cv cv) async {
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
      // Mise en file acquittee localement : l'appelant recoit le CV porteur de
      // l'id temporaire, deja present dans le store.
      return Success(offlineCv);
    }

    final result = await _createCv(cv);
    switch (result) {
      case Success(:final data):
        _store.addCv(data, makeCurrent: true);
        _store.setState(const CvOperationState.success());
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
    }
    return result;
  }

  @override
  Future<Result<Cv>> update(int id, Cv cv) async {
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
      // Mise en file acquittee localement : le store porte deja cette version.
      return Success(cv);
    }

    final result = await _updateCv(UpdateCvParams(id: id, cv: cv));
    switch (result) {
      case Success(:final data):
        _store.replaceCv(id, data);
        _store.setState(const CvOperationState.success());
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
    }
    return result;
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

  @override
  Future<Result<Cv>> createVariant(int cvId, String jobDescription,
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
      case Failure(:final exception):
        _store.setState(CvOperationState.failure(exception.message));
    }
    return result;
  }

  Future<bool> applyAiEnhancements(int cvId, Map<String, dynamic> result) async {
    final cv = _store.currentCv;
    if (cv == null || cv.id != cvId) return false;

    final updatedCv = _applyAi(cv, result);
    return _persist(cvId, updatedCv);
  }

  /// Applique un resultat d'amelioration IA TYPE (issue #244) : voie sans
  /// `Map`, pour la presentation refondue de #244. Meme effet que
  /// [applyAiEnhancements] mais a partir de l'entite [EnhancedCv].
  Future<bool> applyEnhancedCv(int cvId, EnhancedCv enhanced) async {
    final cv = _store.currentCv;
    if (cv == null || cv.id != cvId) return false;

    final updatedCv = _applyAi.fromEnhanced(cv, enhanced);
    return _persist(cvId, updatedCv);
  }

  Future<bool> _persist(int cvId, Cv updatedCv) async {
    final result = await _repository.updateCv(cvId, updatedCv);
    switch (result) {
      case Success(:final data):
        // Reconcilier le store avec la version serveur (ids/normalisation).
        _store.replaceCv(cvId, data);
        _store.setCurrentCv(data);
        return true;
      case Failure():
        // Echec d'ecriture serveur : ne pas pretendre au succes ni laisser
        // d'etat local non persiste (aucune mise a jour optimiste appliquee).
        return false;
    }
  }
}
