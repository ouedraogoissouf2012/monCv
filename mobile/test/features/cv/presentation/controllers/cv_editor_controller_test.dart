import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../flows/helpers/mock_definitions.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late MockCreateCvUseCase create;
  late MockUpdateCvUseCase update;
  late MockDeleteCvUseCase delete;
  late MockDuplicateCvUseCase duplicate;
  late MockCreateVariantUseCase variant;
  late MockCvRepository repository;
  late CvStore store;
  late CvEditorController editor;

  setUp(() {
    create = MockCreateCvUseCase();
    update = MockUpdateCvUseCase();
    delete = MockDeleteCvUseCase();
    duplicate = MockDuplicateCvUseCase();
    variant = MockCreateVariantUseCase();
    repository = MockCvRepository();
    store = CvStore();
    editor = CvEditorController(
      createCv: create,
      updateCv: update,
      deleteCv: delete,
      duplicateCv: duplicate,
      createVariant: variant,
      repository: repository,
      store: store,
      syncQueue: null,
    );
  });

  Cv cv(int id, {String titre = 'CV'}) => Cv(id: id, titre: titre);

  group('CvEditorController - create (#240)', () {
    test('succes : ajoute au store, le rend courant, etat success', () async {
      when(() => create(any()))
          .thenAnswer((_) async => Success(cv(10, titre: 'Nouveau')));

      final ok = await editor.create(cv(0, titre: 'Nouveau'));

      expect(ok, isTrue);
      expect(store.cvs.single.id, 10);
      expect(store.currentCv?.id, 10);
      expect(store.state, isA<CvSuccess>());
    });

    test('echec : etat failure, liste inchangee', () async {
      when(() => create(any())).thenAnswer(
          (_) async => const Failure(NetworkException(message: 'offline')));

      final ok = await editor.create(cv(0));

      expect(ok, isFalse);
      expect(store.cvs, isEmpty);
      expect(store.state.errorMessage, 'offline');
    });
  });

  group('CvEditorController - update / delete', () {
    test('update succes : remplace dans le store (liste + courant)', () async {
      store.setCvs([cv(1, titre: 'ancien')]);
      store.setCurrentCv(cv(1, titre: 'ancien'));
      when(() => update(any()))
          .thenAnswer((_) async => Success(cv(1, titre: 'maj')));

      final ok = await editor.update(1, cv(1, titre: 'maj'));

      expect(ok, isTrue);
      expect(store.cvs.single.titre, 'maj');
      expect(store.currentCv?.titre, 'maj');
    });

    test('delete succes : retire du store', () async {
      store.setCvs([cv(1), cv(2)]);
      when(() => delete(any())).thenAnswer((_) async => const Success(null));

      final ok = await editor.delete(1);

      expect(ok, isTrue);
      expect(store.cvs.map((c) => c.id), [2]);
    });
  });

  group('CvEditorController - duplicate / variant', () {
    test('duplicate succes : ajoute la copie', () async {
      store.setCvs([cv(1)]);
      when(() => duplicate(any()))
          .thenAnswer((_) async => Success(cv(2, titre: 'Copie')));

      final ok = await editor.duplicate(1);

      expect(ok, isTrue);
      expect(store.cvs.length, 2);
    });

    test('createVariant succes : retourne et ajoute la variante', () async {
      store.setCvs([cv(1)]);
      when(() => variant(any()))
          .thenAnswer((_) async => Success(cv(3, titre: 'Variante')));

      final result = await editor.createVariant(1, 'offre');

      expect(result?.id, 3);
      expect(store.cvs.length, 2);
    });
  });

  group('CvEditorController - applyAiEnhancements', () {
    test('sans CV courant correspondant : retourne false', () async {
      store.setCurrentCv(cv(1));
      final ok = await editor.applyAiEnhancements(99, {'titrePoste': 'X'});
      expect(ok, isFalse);
    });

    test('succes : applique, persiste et reconcilie avec la version serveur',
        () async {
      final base = Cv(
        id: 1,
        titre: 'CV',
        personalInfo: const PersonalInfo(
            nom: 'A', prenom: 'B', titrePoste: 'Ancien'),
      );
      store.setCurrentCv(base);
      store.setCvs([base]);
      // Le serveur echo le CV persiste (l'amelioree).
      when(() => repository.updateCv(any(), any())).thenAnswer(
          (inv) async => Success(inv.positionalArguments[1] as Cv));

      final ok = await editor.applyAiEnhancements(1, {'titrePoste': 'Lead'});

      expect(ok, isTrue);
      expect(store.currentCv?.personalInfo?.titrePoste, 'Lead',
          reason: 'amelioration reellement appliquee et reflechie dans le store');
      verify(() => repository.updateCv(1, any())).called(1);
    });

    test(
        'echec de persistance serveur : retourne false (pas de faux succes) [M-2]',
        () async {
      final base = Cv(
        id: 1,
        titre: 'CV',
        personalInfo: const PersonalInfo(
            nom: 'A', prenom: 'B', titrePoste: 'Ancien'),
      );
      store.setCurrentCv(base);
      store.setCvs([base]);
      when(() => repository.updateCv(any(), any())).thenAnswer(
          (_) async => const Failure(NetworkException(message: 'offline')));

      final ok = await editor.applyAiEnhancements(1, {'titrePoste': 'Lead'});

      expect(ok, isFalse,
          reason: 'un echec serveur ne doit jamais etre rapporte comme succes');
      expect(store.currentCv?.personalInfo?.titrePoste, 'Ancien',
          reason: 'aucun etat local non persiste apres echec');
      verify(() => repository.updateCv(1, any())).called(1);
    });

    test(
        'applyEnhancedCv (voie typee) : echec serveur -> false, store inchange [M-2]',
        () async {
      final base = Cv(
        id: 1,
        titre: 'CV',
        personalInfo: const PersonalInfo(
            nom: 'A', prenom: 'B', titrePoste: 'Ancien'),
      );
      store.setCurrentCv(base);
      store.setCvs([base]);
      when(() => repository.updateCv(any(), any())).thenAnswer(
          (_) async => const Failure(ServerException(message: 'boom')));

      final ok = await editor.applyEnhancedCv(
          1, const EnhancedCv(titrePoste: 'Lead'));

      expect(ok, isFalse);
      expect(store.currentCv?.personalInfo?.titrePoste, 'Ancien');
      verify(() => repository.updateCv(1, any())).called(1);
    });
  });
}
