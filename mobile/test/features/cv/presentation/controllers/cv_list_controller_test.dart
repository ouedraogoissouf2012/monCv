import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../flows/helpers/mock_definitions.dart';

/// Caracterise [CvListController] : chargement de la liste (succes/echec),
/// applique au [CvStore] partage. Extrait de `CvProvider` (#240, suite de la
/// revue thermo-nucleaire de #416).
void main() {
  setUpAll(registerAllFallbackValues);

  late MockGetAllCvsUseCase getAll;
  late CvStore store;
  late CvListController controller;

  setUp(() {
    getAll = MockGetAllCvsUseCase();
    store = CvStore();
    controller = CvListController(getAllCvs: getAll, store: store);
  });

  group('CvListController - load (#240)', () {
    test('etat initial : liste vide, pas de chargement', () {
      expect(store.cvs, isEmpty);
      expect(store.state.isLoading, isFalse);
    });

    test('succes : peuple le store, etat success', () async {
      final cvs = [
        Cv(id: 1, titre: 'CV 1'),
        Cv(id: 2, titre: 'CV 2'),
      ];
      when(() => getAll(any())).thenAnswer((_) async => Result.success(cvs));

      await controller.load();

      expect(store.cvs.length, 2);
      expect(store.state, isA<CvSuccess>());
    });

    test('echec : liste inchangee, erreur exposee', () async {
      when(() => getAll(any())).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Erreur reseau')));

      await controller.load();

      expect(store.cvs, isEmpty);
      expect(store.state.errorMessage, 'Erreur reseau');
    });
  });
}
