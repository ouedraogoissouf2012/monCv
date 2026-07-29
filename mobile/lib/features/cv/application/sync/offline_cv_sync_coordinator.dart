import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../services/sync_queue.dart';
import '../../../../usecases/cv/create_cv_usecase.dart';
import '../../../../usecases/cv/update_cv_usecase.dart';
import '../../../../usecases/cv/delete_cv_usecase.dart';
import '../../data/cv_cache_codec.dart';
import '../../presentation/cv_store.dart';

/// Rejoue les mutations CV mises en file d'attente hors ligne, quand la
/// connexion revient (issue #240).
///
/// Extrait de `CvProvider` : le provider ne connait plus la couche `data`
/// (codec) ni les details du replay. Chaque operation qui echoue est
/// conservee dans la file pour un nouvel essai ; l'erreur est capturee de
/// facon TYPEE (pas de `catch` vide) et journalisee sans PII.
class OfflineCvSyncCoordinator {
  final CreateCvUseCase _createCv;
  final UpdateCvUseCase _updateCv;
  final DeleteCvUseCase _deleteCv;
  final SyncQueue _queue;
  final CvStore _store;

  OfflineCvSyncCoordinator({
    required CreateCvUseCase createCv,
    required UpdateCvUseCase updateCv,
    required DeleteCvUseCase deleteCv,
    required SyncQueue queue,
    required CvStore store,
  })  : _createCv = createCv,
        _updateCv = updateCv,
        _deleteCv = deleteCv,
        _queue = queue,
        _store = store;

  /// Rejoue toutes les operations en attente. Sans effet si la file est vide.
  Future<void> replayPending() async {
    if (!_queue.hasPending) return;

    for (final op in _queue.getAll()) {
      try {
        await _replayOne(op);
      } on AppException catch (e) {
        // Erreur applicative connue (reseau, serveur...) : on garde l'op en
        // file pour reessayer, sans exposer de PII.
        debugPrint('[offline-sync] echec ${op.type} (${e.code}), conserve');
      } on FormatException catch (e) {
        // Payload corrompu : idem, on conserve et on trace le type d'erreur.
        debugPrint('[offline-sync] payload invalide ${op.type}: ${e.message}');
      }
    }
  }

  Future<void> _replayOne(PendingOperation op) async {
    switch (op.type) {
      case 'create':
        final cv = cvFromQueueString(op.cvJson);
        if (cv == null) return;
        final result = await _createCv(cv);
        if (result case Success(:final data)) {
          if (op.cvId != null) _store.replaceCv(op.cvId!, data);
          await _queue.remove(op.id);
        }
      case 'update':
        final cv = cvFromQueueString(op.cvJson);
        if (cv == null || op.cvId == null || op.cvId! <= 0) return;
        final result = await _updateCv(UpdateCvParams(id: op.cvId!, cv: cv));
        if (result.isSuccess) await _queue.remove(op.id);
      case 'delete':
        if (op.cvId == null || op.cvId! <= 0) return;
        final result = await _deleteCv(op.cvId!);
        if (result.isSuccess) await _queue.remove(op.id);
    }
  }
}
