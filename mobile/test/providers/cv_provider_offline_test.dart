import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/services/sync_queue.dart';

import 'helpers/cv_provider_harness.dart';

/// Caracterise le mode offline persistant de [CvProvider] : les operations
/// hors ligne sont enfilees dans [SyncQueue] avec un id temporaire negatif.
/// Decoupe depuis `cv_provider_test.dart` (#234).
void main() {
  late CvProviderHarness harness;
  late SyncQueue syncQueue;

  setUp(() async {
    harness = CvProviderHarness();
    harness.setUp();
    syncQueue = await CvProviderHarness.newSyncQueue();
  });

  tearDown(() => harness.tearDown());

  /// Construit un provider adosse a la [SyncQueue] et bascule offline.
  CvProvider buildOfflineProvider() {
    final provider = harness.buildProvider(syncQueue: syncQueue);
    harness.connectivityController.add(false);
    return provider;
  }

  group('CvProvider offline', () {
    test('createCv offline : sauvegarde localement avec ID temp negatif',
        () async {
      final provider = buildOfflineProvider();
      await Future.microtask(() {}); // Laisser le stream emettre

      final result = await provider.createCv(minimalCv(titre: 'CV Offline'));

      expect(result, true);
      expect(provider.cvs.length, 1);
      expect(provider.cvs.first.id, lessThan(0)); // ID temporaire negatif
      expect(syncQueue.hasPending, true);
      expect(syncQueue.pendingCount, 1);
      expect(syncQueue.getAll().first.type, 'create');
    });

    test('isPendingSync retourne true pour CV avec ID negatif', () async {
      final provider = buildOfflineProvider();
      await Future.microtask(() {});

      await provider.createCv(minimalCv(titre: 'CV Offline'));

      expect(provider.isPendingSync(provider.cvs.first), true);
      expect(provider.isPendingSync(minimalCv(id: 10)), false);
    });
  });
}
