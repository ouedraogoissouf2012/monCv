import 'dart:async';
import 'package:flutter/foundation.dart';

import '../features/ai/domain/entities/enhanced_cv.dart';
import '../features/cv/application/state/cv_operation_state.dart';
import '../features/cv/application/sync/offline_cv_sync_coordinator.dart';
import '../features/cv/presentation/controllers/cv_detail_controller.dart';
import '../features/cv/presentation/controllers/cv_editor_controller.dart';
import '../features/cv/presentation/controllers/cv_list_controller.dart';
import '../features/cv/presentation/controllers/cv_style_controller.dart';
import '../features/cv/presentation/cv_store.dart';
import '../models/cv.dart';
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

/// Facade de compatibilite au-dessus du [CvStore] et des controllers CV
/// (list / detail / editor / style) introduits par #240.
///
/// Elle ne contient plus de logique metier : chaque appel est delegue au bon
/// controller, et l'etat unique vit dans le [CvStore]. Les widgets continuent
/// d'ecouter ce `ChangeNotifier` et d'utiliser la meme API publique.
///
/// A retirer une fois les ecrans migres pour consommer directement le store et
/// les controllers (suite de #240).
@Deprecated('Utiliser CvStore + les controllers CV (features/cv/presentation). '
    'Facade de migration #240, a supprimer apres migration des ecrans.')
class CvProvider with ChangeNotifier {
  final CvStore _store;
  final CvListController _list;
  final CvDetailController _detail;
  final CvEditorController _editor;
  final CvStyleController _style;
  final ConnectivityService _connectivity;
  final SyncQueue? _syncQueue;
  final OfflineCvSyncCoordinator? _syncCoordinator;

  late final StreamSubscription<bool> _connectivitySub;

  /// Point d'entree (DI). Cree le [CvStore] partage et cable les controllers
  /// dessus pour garantir une source unique d'etat.
  factory CvProvider({
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
    CvStore? store,
  }) {
    final sharedStore = store ?? CvStore();
    return CvProvider._(
      store: sharedStore,
      connectivity: connectivity,
      syncQueue: syncQueue,
      syncCoordinator: syncQueue == null
          ? null
          : OfflineCvSyncCoordinator(
              createCv: createCv,
              updateCv: updateCv,
              deleteCv: deleteCv,
              queue: syncQueue,
              store: sharedStore,
            ),
      list: CvListController(getAllCvs: getAllCvs, store: sharedStore),
      detail: CvDetailController(getCvById: getCvById, store: sharedStore),
      editor: CvEditorController(
        createCv: createCv,
        updateCv: updateCv,
        deleteCv: deleteCv,
        duplicateCv: duplicateCv,
        createVariant: createVariantUseCase,
        repository: repository,
        store: sharedStore,
        syncQueue: syncQueue,
      ),
      style: CvStyleController(repository: repository, store: sharedStore),
    );
  }

  CvProvider._({
    required CvStore store,
    required ConnectivityService connectivity,
    required SyncQueue? syncQueue,
    required OfflineCvSyncCoordinator? syncCoordinator,
    required CvListController list,
    required CvDetailController detail,
    required CvEditorController editor,
    required CvStyleController style,
  })  : _store = store,
        _connectivity = connectivity,
        _syncQueue = syncQueue,
        _syncCoordinator = syncCoordinator,
        _list = list,
        _detail = detail,
        _editor = editor,
        _style = style {
    _store.addListener(notifyListeners);
    // Etat initial de connectivite avant toute mutation (#240, C4).
    _initConnectivity();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) async {
      _store.setOffline(!online);
      if (online) {
        // Rejouer la file (reconciliation d'ids, deletes en attente) AVANT de
        // decider un rechargement : sinon un GET liste concurrent peut ecraser
        // une reconciliation en cours ou faire reapparaitre un CV supprime.
        await _syncPendingOperations();
        if (_store.cvs.isEmpty) loadCvs();
      }
    });
  }

  Future<void> _initConnectivity() async {
    final online = await _connectivity.isConnected();
    _store.setOffline(!online);
  }

  // ── Etat expose (derive du store) ──────────────────────────────
  CvOperationState get state => _store.state;
  List<Cv> get cvs => _store.cvs;
  Cv? get currentCv => _store.currentCv;
  bool get isLoading => _store.state.isLoading;
  bool get isOffline => _store.isOffline;
  String? get error => _store.state.errorMessage;
  bool get hasPendingSync => _syncQueue?.hasPending ?? false;
  int get pendingSyncCount => _syncQueue?.pendingCount ?? 0;

  // ── Delegations ───────────────────────────────────────────────
  Future<void> loadCvs() => _list.load();
  Future<void> loadCvById(int id) => _detail.load(id);
  Future<bool> createCv(Cv cv) => _editor.create(cv);
  Future<bool> updateCv(int id, Cv cv) => _editor.update(id, cv);
  Future<bool> deleteCv(int id) => _editor.delete(id);
  Future<bool> duplicateCv(int id) => _editor.duplicate(id);
  Future<Cv?> createVariant(int cvId, String jobDescription, {String? label}) =>
      _editor.createVariant(cvId, jobDescription, label: label);
  Future<bool> applyAiEnhancements(int cvId, Map<String, dynamic> result) =>
      _editor.applyAiEnhancements(cvId, result);
  Future<bool> applyEnhancedCv(int cvId, EnhancedCv enhanced) =>
      _editor.applyEnhancedCv(cvId, enhanced);
  Future<bool> updateCvStyle(int cvId, CvStyle style) =>
      _style.update(cvId, style);
  void setCurrentCv(Cv? cv) => _detail.select(cv);
  void clearError() => _store.setState(const CvOperationState.idle());

  /// True si ce CV a un ID temporaire negatif (cree offline, pas encore sync).
  bool isPendingSync(Cv cv) => cv.id != null && cv.id! < 0;

  // Rejeu des mutations offline, delegue au coordinateur (#240).
  Future<void> _syncPendingOperations() async {
    await _syncCoordinator?.replayPending();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}
