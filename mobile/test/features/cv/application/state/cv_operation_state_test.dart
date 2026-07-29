import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvOperationState - etats mutuellement exclusifs (#240)', () {
    test('idle : aucun predicat actif', () {
      const state = CvOperationState.idle();
      expect(state.isLoading, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.isPendingSync, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('loading : seul isLoading est vrai', () {
      const state = CvOperationState.loading();
      expect(state.isLoading, isTrue);
      expect(state.isFailure, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.isPendingSync, isFalse);
    });

    test('failure : expose message et code, isFailure seul actif', () {
      const state = CvOperationState.failure('Echec reseau', code: 'NETWORK');
      expect(state.isFailure, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Echec reseau');
      expect((state as CvFailure).code, 'NETWORK');
    });

    test('failure sans code : code null, message conserve', () {
      const state = CvOperationState.failure('Erreur');
      expect(state.errorMessage, 'Erreur');
      expect((state as CvFailure).code, isNull);
    });

    test('offline : seul isOffline est vrai', () {
      const state = CvOperationState.offline();
      expect(state.isOffline, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isFailure, isFalse);
    });

    test('pendingSync : expose le nombre en attente', () {
      const state = CvOperationState.pendingSync(3);
      expect(state.isPendingSync, isTrue);
      expect((state as CvPendingSync).count, 3);
    });

    test('success : aucun predicat d erreur/chargement', () {
      const state = CvOperationState.success();
      expect(state.isLoading, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('le switch exhaustif couvre tous les etats (compile-time safety)', () {
      String label(CvOperationState s) => switch (s) {
            CvIdle() => 'idle',
            CvLoading() => 'loading',
            CvSuccess() => 'success',
            CvFailure() => 'failure',
            CvOffline() => 'offline',
            CvPendingSync() => 'pendingSync',
          };

      expect(label(const CvOperationState.idle()), 'idle');
      expect(label(const CvOperationState.loading()), 'loading');
      expect(label(const CvOperationState.success()), 'success');
      expect(label(const CvOperationState.failure('x')), 'failure');
      expect(label(const CvOperationState.offline()), 'offline');
      expect(label(const CvOperationState.pendingSync(1)), 'pendingSync');
    });
  });
}
