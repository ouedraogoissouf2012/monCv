import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_style_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../flows/helpers/mock_definitions.dart';

/// Caracterise [CvStyleController] : application optimiste d'un style puis
/// persistance. Extrait de `CvProvider` (#240, suite de la revue
/// thermo-nucleaire de #416).
///
/// A distinguer de `features/cv_style/presentation/cv_style_controller.dart`
/// (edition locale dans l'ecran de style), classe homonyme non liee.
void main() {
  setUpAll(registerAllFallbackValues);

  late MockCvRepository repository;
  late CvStore store;
  late CvStyleController controller;

  const sampleStyle = CvStyle(
    templateId: 'classique',
    primaryColor: Color(0xFF10B981),
    fontFamily: 'Lato',
  );

  setUp(() {
    repository = MockCvRepository();
    store = CvStore();
    controller = CvStyleController(repository: repository, store: store);
  });

  group('CvStyleController - update (#240)', () {
    test('succes : applique puis persiste le style via le repository',
        () async {
      final cv = Cv(id: 7, titre: 'CV');
      store.setCurrentCv(cv);
      when(() => repository.updateCv(7, any())).thenAnswer(
          (inv) async => Result.success(inv.positionalArguments[1] as Cv));

      final ok = await controller.update(7, sampleStyle);

      expect(ok, isTrue);
      expect(store.currentCv?.style.templateId, 'classique');
      expect(store.currentCv?.style.primaryColor.toARGB32(), 0xFF10B981);
      expect(store.currentCv?.style.fontFamily, 'Lato');
      verify(() => repository.updateCv(7, any())).called(1);
    });

    test('CV introuvable : retourne false, aucun appel au repository',
        () async {
      final ok = await controller.update(99, sampleStyle);

      expect(ok, isFalse);
      expect(store.state.errorMessage, isNotNull);
      verifyNever(() => repository.updateCv(any(), any()));
    });

    test(
        'echec de persistance : le store revient au style original (pas de faux succes affiche)',
        () async {
      final original = Cv(id: 7, titre: 'CV', style: CvStyle.defaultStyle);
      store.setCurrentCv(original);
      when(() => repository.updateCv(7, any())).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'offline')));

      final ok = await controller.update(7, sampleStyle);

      expect(ok, isFalse);
      expect(store.currentCv?.style, CvStyle.defaultStyle,
          reason:
              'le style optimiste non persiste ne doit pas rester affiche apres un echec serveur');
      expect(store.state.errorMessage, 'offline');
    });
  });
}
