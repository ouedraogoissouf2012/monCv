import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/error/result.dart';
import '../core/usecase/usecase.dart';
import '../features/cv/application/apply_ai_enhancements.dart';
import '../features/cv/application/state/cv_operation_state.dart';
import '../features/cv/data/cv_cache_codec.dart';
import '../features/cv/presentation/cv_presentation_model.dart';
import '../models/cv_style.dart';
import '../repositories/cv_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_queue.dart';
import '../usecases/cv/get_all_cvs_usecase.dart';
import '../usecases/cv/get_cv_by_id_usecase.dart';
import '../usecases/cv/create_cv_usecase.dart';
import '../usecases/cv/update_cv_usecase.dart';
import '../usecases/cv/delete_cv_usecase.dart';
import '../usecases/cv/duplicate_cv_usecase.dart';
import '../usecases/cv/create_variant_usecase.dart';

class CvProvider with ChangeNotifier {
  final GetAllCvsUseCase _getAllCvs;
  final GetCvByIdUseCase _getCvById;
  final CreateCvUseCase _createCv;
  final UpdateCvUseCase _updateCv;
  final DeleteCvUseCase _deleteCv;
  final DuplicateCvUseCase _duplicateCv;
  final CreateVariantUseCase _createVariant;
  final CvRepository _repository;
  final ConnectivityService _connectivity;
  final SyncQueue? _syncQueue;
  final ApplyAiEnhancements _applyAiEnhancements = const ApplyAiEnhancements();

  late final StreamSubscription<bool> _connectivitySub;
  int _tempIdCounter = -1;

  CvProvider({
    required GetAllCvsUseCase getAllCvs,
    required GetCvByIdUseCase getCvById,
    required CreateCvUseCase createCv,
    required UpdateCvUseCase updateCv,
    required DeleteCvUseCase deleteCv,
    required DuplicateCvUseCase duplicateCv,
    required CreateVariantUseCase createVariantUseCase,
    required CvRepository repository,
    required ConnectivityService connectivity,
    SyncQueue? syncQueue,
  })  : _getAllCvs = getAllCvs,
        _getCvById = getCvById,
        _createCv = createCv,
        _updateCv = updateCv,
        _deleteCv = deleteCv,
        _duplicateCv = duplicateCv,
        _createVariant = createVariantUseCase,
        _repository = repository,
        _connectivity = connectivity,
        _syncQueue = syncQueue {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      _isOffline = !online;
      notifyListeners();
      if (online) {
        _syncPendingOperations();
        if (_cvs.isEmpty) loadCvs();
      }
    });
  }

  List<Cv> _cvs = [];
  Cv? _currentCv;

  // Etat unique et typE (#240) : remplace les booleans concurrents
  // `_isLoading` / `_error` / `_isOffline` qui pouvaient se contredire.
  // Les getters historiques ci-dessous en derivent pour ne rien casser cote UI.
  CvOperationState _state = const CvOperationState.idle();

  CvOperationState get state => _state;

  List<Cv> get cvs => _cvs;
  Cv? get currentCv => _currentCv;
  bool get isLoading => _state.isLoading;
  bool get hasPendingSync => _syncQueue?.hasPending ?? false;
  int get pendingSyncCount => _syncQueue?.pendingCount ?? 0;
  String? get error => _state.errorMessage;
  bool get isOffline => _isOffline;
  bool _isOffline = false;

  void _setState(CvOperationState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> loadCvs() async {
    _setState(const CvOperationState.loading());

    final result = await _getAllCvs(const NoParams());

    switch (result) {
      case Success(:final data):
        _cvs = data;
        _setState(const CvOperationState.success());
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
    }
  }

  Future<void> loadCvById(int id) async {
    _setState(const CvOperationState.loading());

    final result = await _getCvById(id);

    switch (result) {
      case Success(:final data):
        _currentCv = data;
        _setState(const CvOperationState.success());
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
    }
  }

  Future<bool> createCv(Cv cv) async {
    _setState(const CvOperationState.loading());

    // Si offline, sauvegarder localement avec un ID temporaire negatif
    if (_isOffline && _syncQueue != null) {
      final tempId = _tempIdCounter--;
      final offlineCv = cv.copyWith(id: tempId);
      _cvs.add(offlineCv);
      _currentCv = offlineCv;
      await _syncQueue!.add(PendingOperation(
        id: 'create_$tempId',
        type: 'create',
        cvJson: cvToQueueString(cv),
        cvId: tempId,
        createdAt: DateTime.now(),
      ));
      _setState(CvOperationState.pendingSync(pendingSyncCount));
      return true;
    }

    final result = await _createCv(cv);

    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        _currentCv = data;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> updateCv(int id, Cv cv) async {
    _setState(const CvOperationState.loading());

    // Si offline, sauvegarder localement + queue
    if (_isOffline && _syncQueue != null) {
      final index = _cvs.indexWhere((c) => c.id == id);
      if (index != -1) _cvs[index] = cv;
      _currentCv = cv;
      await _syncQueue!.add(PendingOperation(
        id: 'update_${id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'update',
        cvJson: cvToQueueString(cv),
        cvId: id,
        createdAt: DateTime.now(),
      ));
      _setState(CvOperationState.pendingSync(pendingSyncCount));
      return true;
    }

    final result = await _updateCv(UpdateCvParams(id: id, cv: cv));

    switch (result) {
      case Success(:final data):
        final index = _cvs.indexWhere((c) => c.id == id);
        if (index != -1) _cvs[index] = data;
        _currentCv = data;
        _setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> deleteCv(int id) async {
    _setState(const CvOperationState.loading());

    final result = await _deleteCv(id);

    switch (result) {
      case Success():
        _cvs.removeWhere((cv) => cv.id == id);
        if (_currentCv?.id == id) _currentCv = null;
        _setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<bool> duplicateCv(int id) async {
    _setState(const CvOperationState.loading());

    final result = await _duplicateCv(id);

    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        _setState(const CvOperationState.success());
        return true;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  Future<Cv?> createVariant(int cvId, String jobDescription,
      {String? label}) async {
    _setState(const CvOperationState.loading());

    final result = await _createVariant(
      CreateVariantParams(
        cvId: cvId,
        jobDescription: jobDescription,
        label: label,
      ),
    );
    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        _setState(const CvOperationState.success());
        return data;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return null;
    }
  }

  Future<bool> applyAiEnhancements(
      int cvId, Map<String, dynamic> result) async {
    final cv = _currentCv;
    if (cv == null || cv.id != cvId) return false;

    final updatedCv = _applyAiEnhancements(cv, result);

    _currentCv = updatedCv;
    final listIndex = _cvs.indexWhere((c) => c.id == cvId);
    if (listIndex != -1) _cvs[listIndex] = updatedCv;
    notifyListeners();

    // Persistance best-effort : le resultat sera propage par la PR offline.
    await _repository.updateCv(cvId, updatedCv);
    return true;
  }

  Future<bool> updateCvStyle(int cvId, CvStyle style) async {
    final currentIndex = _cvs.indexWhere((c) => c.id == cvId);
    final cv = _currentCv?.id == cvId
        ? _currentCv
        : currentIndex != -1
            ? _cvs[currentIndex]
            : null;

    if (cv == null) {
      _setState(const CvOperationState.failure('CV introuvable'));
      return false;
    }

    final updatedCv = cv.copyWith(style: style);

    if (_currentCv?.id == cvId) {
      _currentCv = updatedCv;
    }
    final index = _cvs.indexWhere((c) => c.id == cvId);
    if (index != -1) {
      _cvs[index] = updatedCv;
    }
    notifyListeners();

    final result = await _repository.updateCv(cvId, updatedCv);
    switch (result) {
      case Success(:final data):
        if (_currentCv?.id == cvId) {
          _currentCv = data;
        }
        final index = _cvs.indexWhere((c) => c.id == cvId);
        if (index != -1) {
          _cvs[index] = data;
        }
        notifyListeners();
        return true;
      case Failure(:final exception):
        _setState(CvOperationState.failure(exception.message));
        return false;
    }
  }

  void setCurrentCv(Cv? cv) {
    _currentCv = cv;
    notifyListeners();
  }

  /// True si ce CV a un ID temporaire negatif (cree offline, pas encore sync).
  bool isPendingSync(Cv cv) => cv.id != null && cv.id! < 0;

  void clearError() {
    _setState(const CvOperationState.idle());
  }

  // ── Sync offline ──────────────────────────────────────────────

  /// Rejoue les operations en attente quand la connexion revient.
  Future<void> _syncPendingOperations() async {
    final queue = _syncQueue;
    if (queue == null || !queue.hasPending) return;

    final operations = queue.getAll();
    for (final op in operations) {
      try {
        switch (op.type) {
          case 'create':
            final cv = cvFromQueueString(op.cvJson);
            if (cv != null) {
              final result = await _createCv(cv);
              if (result case Success(:final data)) {
                final tempIndex = _cvs.indexWhere((c) => c.id == op.cvId);
                if (tempIndex != -1) _cvs[tempIndex] = data;
                await queue.remove(op.id);
              }
            }
          case 'update':
            final cv = cvFromQueueString(op.cvJson);
            if (cv != null && op.cvId != null && op.cvId! > 0) {
              final result =
                  await _updateCv(UpdateCvParams(id: op.cvId!, cv: cv));
              if (result.isSuccess) await queue.remove(op.id);
            }
          case 'delete':
            if (op.cvId != null && op.cvId! > 0) {
              final result = await _deleteCv(op.cvId!);
              if (result.isSuccess) await queue.remove(op.id);
            }
        }
      } catch (_) {
        // Garder dans la queue, reessayer plus tard
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}
