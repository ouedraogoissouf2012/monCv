import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Cv cv(int id, {String titre = 'CV'}) => Cv(id: id, titre: titre);

  group('CvStore - source unique + synchro liste/courant (#240)', () {
    test('setCvs remplace la liste et passe en succes', () {
      final store = CvStore();
      store.setCvs([cv(1), cv(2)]);
      expect(store.cvs.length, 2);
      expect(store.state, isA<CvSuccess>());
    });

    test('la liste exposee est non modifiable', () {
      final store = CvStore()..setCvs([cv(1)]);
      expect(() => store.cvs.add(cv(2)), throwsUnsupportedError);
    });

    test('replaceCv met a jour la liste ET le courant simultanement', () {
      final store = CvStore()
        ..setCvs([cv(1, titre: 'ancien')])
        ..setCurrentCv(cv(1, titre: 'ancien'));

      store.replaceCv(1, cv(1, titre: 'nouveau'));

      expect(store.cvs.single.titre, 'nouveau');
      expect(store.currentCv?.titre, 'nouveau'); // pas de desynchro
    });

    test('replaceCv ne touche pas le courant si l id differe', () {
      final store = CvStore()
        ..setCvs([cv(1), cv(2)])
        ..setCurrentCv(cv(2, titre: 'courant'));

      store.replaceCv(1, cv(1, titre: 'modifie'));

      expect(store.currentCv?.id, 2);
      expect(store.currentCv?.titre, 'courant'); // inchange
    });

    test('removeCv retire de la liste et vide le courant si c etait lui', () {
      final store = CvStore()
        ..setCvs([cv(1), cv(2)])
        ..setCurrentCv(cv(1));

      store.removeCv(1);

      expect(store.cvs.map((c) => c.id), [2]);
      expect(store.currentCv, isNull);
    });

    test('addCv avec makeCurrent ajoute et rend courant', () {
      final store = CvStore()..setCvs([cv(1)]);
      store.addCv(cv(2), makeCurrent: true);
      expect(store.cvs.length, 2);
      expect(store.currentCv?.id, 2);
    });

    test('setOffline ne notifie que sur changement reel', () {
      final store = CvStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.setOffline(true);
      store.setOffline(true); // idempotent, pas de nouvelle notif
      expect(store.isOffline, isTrue);
      expect(notifications, 1);
    });

    test('setState propage l etat et notifie', () {
      final store = CvStore();
      var notified = false;
      store.addListener(() => notified = true);
      store.setState(const CvOperationState.failure('boom'));
      expect(store.state.errorMessage, 'boom');
      expect(notified, isTrue);
    });
  });
}
