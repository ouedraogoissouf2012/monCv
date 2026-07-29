import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/application/sync/offline_cv_sync_coordinator.dart';
import 'package:cv_mobile/features/cv/data/cv_cache_codec.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../flows/helpers/mock_definitions.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late MockCreateCvUseCase create;
  late MockUpdateCvUseCase update;
  late MockDeleteCvUseCase delete;
  late SyncQueue queue;
  late CvStore store;
  late OfflineCvSyncCoordinator coordinator;

  Cv cv(int id, {String titre = 'CV'}) => Cv(id: id, titre: titre);

  PendingOperation op(String type, int cvId) => PendingOperation(
        id: '${type}_$cvId',
        type: type,
        cvJson: cvToQueueString(cv(cvId)),
        cvId: cvId,
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    create = MockCreateCvUseCase();
    update = MockUpdateCvUseCase();
    delete = MockDeleteCvUseCase();
    queue = SyncQueue(prefs);
    store = CvStore();
    coordinator = OfflineCvSyncCoordinator(
      createCv: create,
      updateCv: update,
      deleteCv: delete,
      queue: queue,
      store: store,
    );
  });

  group('OfflineCvSyncCoordinator - replay (#240)', () {
    test('file vide : ne fait rien', () async {
      await coordinator.replayPending();
      expect(queue.hasPending, isFalse);
      verifyNever(() => create(any()));
    });

    test('create rejoue avec succes : retire de la file + maj store', () async {
      // Id temporaire negatif -> id reel apres sync.
      await queue.add(PendingOperation(
        id: 'create_-1',
        type: 'create',
        cvJson: cvToQueueString(cv(-1)),
        cvId: -1,
        createdAt: DateTime(2026, 1, 1),
      ));
      store.addCv(cv(-1));
      when(() => create(any())).thenAnswer((_) async => Success(cv(42)));

      await coordinator.replayPending();

      expect(queue.hasPending, isFalse); // op retiree
      expect(store.cvs.single.id, 42); // temp remplace par l'id reel
    });

    test('update rejoue avec succes : retire de la file', () async {
      await queue.add(op('update', 5));
      when(() => update(any())).thenAnswer((_) async => Success(cv(5)));

      await coordinator.replayPending();

      expect(queue.hasPending, isFalse);
      verify(() => update(any())).called(1);
    });

    test('delete rejoue avec succes : retire de la file', () async {
      await queue.add(op('delete', 7));
      when(() => delete(any())).thenAnswer((_) async => const Success(null));

      await coordinator.replayPending();

      expect(queue.hasPending, isFalse);
    });

    test('echec applicatif : operation CONSERVEE pour reessai', () async {
      await queue.add(op('update', 9));
      when(() => update(any())).thenAnswer(
          (_) async => const Failure(NetworkException(message: 'offline')));

      await coordinator.replayPending();

      expect(queue.hasPending, isTrue); // pas retiree
    });

    test('exception applicative levee : capturee, op conservee, pas de crash',
        () async {
      await queue.add(op('delete', 11));
      when(() => delete(any()))
          .thenThrow(const NetworkException(message: 'timeout'));

      // Ne doit pas relancer l'exception.
      await coordinator.replayPending();

      expect(queue.hasPending, isTrue);
    });
  });
}
