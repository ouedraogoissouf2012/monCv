import 'dart:async';

import '../../../../services/connectivity_service.dart';
import '../../application/sync/offline_cv_sync_coordinator.dart';
import '../cv_store.dart';
import 'cv_list_controller.dart';

/// Orchestre la connectivite pour le domaine CV (issue #240 ; extrait de
/// l'ancien `CvProvider`, cf. revue thermo-nucleaire de #416).
///
/// Suit l'etat en ligne/hors ligne dans le [CvStore] et rejoue les mutations
/// en attente via [OfflineCvSyncCoordinator] au retour de connexion, avant de
/// recharger la liste si necessaire.
///
/// IMPORTANT : ce controleur est enregistre en DI et doit etre EXPLICITEMENT
/// reveille au demarrage de l'app (dans `main()`, apres `initDependencies()`).
/// Contrairement a un `ChangeNotifierProvider` (paresseux : `create` n'est
/// appele qu'a la premiere lecture), l'ecoute de connectivite doit demarrer
/// des le lancement, independamment de toute lecture par l'UI — sinon elle ne
/// s'active jamais si aucun widget ne lit ce controleur.
class CvConnectivitySyncController {
  final ConnectivityService _connectivity;
  final CvStore _store;
  final CvListController _list;
  final OfflineCvSyncCoordinator? _syncCoordinator;

  late final StreamSubscription<bool> _connectivitySub;

  CvConnectivitySyncController({
    required ConnectivityService connectivity,
    required CvStore store,
    required CvListController list,
    OfflineCvSyncCoordinator? syncCoordinator,
  })  : _connectivity = connectivity,
        _store = store,
        _list = list,
        _syncCoordinator = syncCoordinator {
    _initConnectivity();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((online) async {
      _store.setOffline(!online);
      if (online) {
        // Rejouer la file (reconciliation d'ids, deletes en attente) AVANT de
        // decider un rechargement : sinon un GET liste concurrent peut ecraser
        // une reconciliation en cours ou faire reapparaitre un CV supprime.
        await _syncCoordinator?.replayPending();
        if (_store.cvs.isEmpty) _list.load();
      }
    });
  }

  Future<void> _initConnectivity() async {
    final online = await _connectivity.isConnected();
    _store.setOffline(!online);
  }

  void dispose() => _connectivitySub.cancel();
}
