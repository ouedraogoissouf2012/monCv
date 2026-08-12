import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/providers/cv_provider.dart';

import 'helpers/cv_provider_harness.dart';

/// Caracterise la creation de variantes de CV (CV cible d'une offre) et le
/// marqueur `isVariante`. Decoupe depuis `cv_provider_test.dart` (#234).
void main() {
  late CvProviderHarness harness;

  setUp(() {
    harness = CvProviderHarness();
    harness.setUp();
  });

  tearDown(() => harness.tearDown());

  CvProvider buildProvider() => harness.buildProvider();

  group('CvProvider variantes', () {
    test('createVariant succes : ajoute la variante a la liste', () async {
      final variant = minimalCv(id: 20, titre: 'Mon CV — Dev Backend');
      when(() => harness.createVariant(any()))
          .thenAnswer((_) async => Result.success(variant));

      final provider = buildProvider();
      final result = await provider.createVariant(10, 'Offre dev backend');

      expect(result, isNotNull);
      expect(result!.id, 20);
      expect(provider.cvs.length, 1);
      expect(provider.cvs.first.titre, 'Mon CV — Dev Backend');
    });

    test('createVariant echec : retourne null, error defini', () async {
      when(() => harness.createVariant(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'IA indisponible')));

      final provider = buildProvider();
      final result = await provider.createVariant(10, 'Offre');

      expect(result, isNull);
      expect(provider.error, 'IA indisponible');
    });

    test('Cv.isVariante retourne true quand varianteLabel defini', () {
      final variant = Cv(
        id: 20,
        titre: 'Variante',
        varianteLabel: 'Dev Backend',
        parentCvId: 10,
      );
      final original = minimalCv(id: 10);

      expect(variant.isVariante, true);
      expect(original.isVariante, false);
    });
  });
}
