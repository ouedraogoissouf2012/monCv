import 'dart:async';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_connectivity_sync_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../flows/helpers/mock_definitions.dart';

/// Caracterise [CvConnectivitySyncController] : suit l'etat en ligne/hors
/// ligne dans le [CvStore]. Extrait de `CvProvider` (#240, suite de la revue
/// thermo-nucleaire de #416) — cette orchestration doit demarrer des le
/// lancement de l'app (cf. doc de la classe), independamment de toute lecture
/// par l'UI.
void main() {
  setUpAll(registerAllFallbackValues);

  late MockConnectivityService connectivity;
  late StreamController<bool> connectivityStream;
  late MockGetAllCvsUseCase getAll;
  late CvStore store;
  late CvListController listController;

  setUp(() {
    connectivity = MockConnectivityService();
    connectivityStream = StreamController<bool>.broadcast();
    getAll = MockGetAllCvsUseCase();
    store = CvStore();
    listController = CvListController(getAllCvs: getAll, store: store);

    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityStream.stream);
    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
  });

  tearDown(() => connectivityStream.close());

  CvConnectivitySyncController build() => CvConnectivitySyncController(
        connectivity: connectivity,
        store: store,
        list: listController,
      );

  group('CvConnectivitySyncController (#240)', () {
    test('perte de connexion : store.isOffline passe a true', () async {
      final controller = build();
      addTearDown(controller.dispose);

      connectivityStream.add(false);
      await Future<void>.delayed(Duration.zero);

      expect(store.isOffline, isTrue);
    });

    test('retour de connexion : store.isOffline repasse a false', () async {
      when(() => getAll(any())).thenAnswer((_) async => const Result.success([]));

      final controller = build();
      addTearDown(controller.dispose);

      connectivityStream.add(false);
      await Future<void>.delayed(Duration.zero);
      connectivityStream.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(store.isOffline, isFalse);
    });

    test('retour de connexion avec liste vide : recharge via CvListController',
        () async {
      when(() => getAll(any())).thenAnswer((_) async => const Result.success([]));

      final controller = build();
      addTearDown(controller.dispose);

      connectivityStream.add(false);
      await Future<void>.delayed(Duration.zero);
      connectivityStream.add(true);
      await Future<void>.delayed(Duration.zero);

      verify(() => getAll(any())).called(1);
    });
  });
}
