import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_detail_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../flows/helpers/mock_definitions.dart';

/// Caracterise [CvDetailController] : chargement d'un CV par id (succes/echec)
/// et selection directe. Extrait de `CvProvider` (#240, suite de la revue
/// thermo-nucleaire de #416).
///
/// A distinguer de `features/cv_detail/presentation/cv_detail_controller.dart`
/// (export PDF/DOCX), classe homonyme non liee.
void main() {
  setUpAll(registerAllFallbackValues);

  late MockGetCvByIdUseCase getById;
  late CvStore store;
  late CvDetailController controller;

  setUp(() {
    getById = MockGetCvByIdUseCase();
    store = CvStore();
    controller = CvDetailController(getCvById: getById, store: store);
  });

  group('CvDetailController - load (#240)', () {
    test('succes : rend le CV courant, etat success', () async {
      final cv = Cv(id: 42, titre: 'CV Detail');
      when(() => getById(42)).thenAnswer((_) async => Result.success(cv));

      await controller.load(42);

      expect(store.currentCv?.id, 42);
      expect(store.state, isA<CvSuccess>());
    });

    test('echec : CV courant inchange, erreur exposee', () async {
      when(() => getById(42)).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'CV introuvable')));

      await controller.load(42);

      expect(store.currentCv, isNull);
      expect(store.state.errorMessage, 'CV introuvable');
    });
  });

  group('CvDetailController - select', () {
    test('select rend le CV donne courant sans appel reseau', () {
      final cv = Cv(id: 7, titre: 'Selection directe');

      controller.select(cv);

      expect(store.currentCv?.id, 7);
      verifyNever(() => getById(any()));
    });
  });
}
