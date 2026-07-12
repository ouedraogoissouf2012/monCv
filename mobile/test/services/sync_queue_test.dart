import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cv_mobile/services/sync_queue.dart';

void main() {
  late SharedPreferences prefs;
  late SyncQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queue = SyncQueue(prefs);
  });

  group('SyncQueue', () {
    test('initialement vide', () {
      expect(queue.hasPending, false);
      expect(queue.pendingCount, 0);
      expect(queue.getAll(), isEmpty);
    });

    test('add ajoute une operation', () async {
      await queue.add(PendingOperation(
        id: 'op1',
        type: 'create',
        cvJson: '{"titre":"Mon CV"}',
        cvId: -1,
        createdAt: DateTime(2024, 6, 1),
      ));

      expect(queue.hasPending, true);
      expect(queue.pendingCount, 1);
      expect(queue.getAll().first.id, 'op1');
      expect(queue.getAll().first.type, 'create');
    });

    test('remove retire une operation par id', () async {
      await queue.add(PendingOperation(
        id: 'op1', type: 'create', cvId: -1, createdAt: DateTime.now(),
      ));
      await queue.add(PendingOperation(
        id: 'op2', type: 'update', cvId: 5, createdAt: DateTime.now(),
      ));

      expect(queue.pendingCount, 2);

      await queue.remove('op1');

      expect(queue.pendingCount, 1);
      expect(queue.getAll().first.id, 'op2');
    });

    test('clear vide toute la queue', () async {
      await queue.add(PendingOperation(
        id: 'op1', type: 'create', cvId: -1, createdAt: DateTime.now(),
      ));
      await queue.add(PendingOperation(
        id: 'op2', type: 'update', cvId: 5, createdAt: DateTime.now(),
      ));

      await queue.clear();

      expect(queue.hasPending, false);
      expect(queue.pendingCount, 0);
    });

    test('persiste entre les instances', () async {
      await queue.add(PendingOperation(
        id: 'op1', type: 'create',
        cvJson: '{"titre":"Offline CV"}',
        cvId: -1,
        createdAt: DateTime(2024, 6, 1),
      ));

      // Nouvelle instance avec les memes SharedPreferences
      final queue2 = SyncQueue(prefs);

      expect(queue2.hasPending, true);
      expect(queue2.getAll().first.cvJson, '{"titre":"Offline CV"}');
    });

    test('serialisation/deserialisation PendingOperation', () {
      final op = PendingOperation(
        id: 'test123',
        type: 'update',
        cvJson: '{"titre":"Test"}',
        cvId: 42,
        createdAt: DateTime(2024, 3, 15, 10, 30),
      );

      final json = op.toJson();
      final restored = PendingOperation.fromJson(json);

      expect(restored.id, 'test123');
      expect(restored.type, 'update');
      expect(restored.cvJson, '{"titre":"Test"}');
      expect(restored.cvId, 42);
      expect(restored.createdAt, DateTime(2024, 3, 15, 10, 30));
    });
  });
}
