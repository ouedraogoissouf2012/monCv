import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv_list/application/import_cv.dart';
import 'package:cv_mobile/features/cv_list/domain/cv_import_policy.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // En-tetes valides.
  final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0, 0]); // %PDF
  final docxBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0, 0]); // PK..

  group('CvImportPolicy.validate (#249 D1)', () {
    test('PDF valide (extension + magic) -> null', () {
      expect(CvImportPolicy.validate('cv.pdf', pdfBytes), isNull);
    });

    test('DOCX valide -> null', () {
      expect(CvImportPolicy.validate('cv.docx', docxBytes), isNull);
    });

    test('extension interdite -> invalidExtension', () {
      expect(CvImportPolicy.validate('cv.exe', pdfBytes),
          CvImportError.invalidExtension);
      expect(CvImportPolicy.validate('cv', pdfBytes),
          CvImportError.invalidExtension);
    });

    test('fichier vide -> empty', () {
      expect(CvImportPolicy.validate('cv.pdf', Uint8List(0)),
          CvImportError.empty);
    });

    test('contenu incoherent (docx renomme en pdf) -> invalidContent', () {
      expect(CvImportPolicy.validate('cv.pdf', docxBytes),
          CvImportError.invalidContent);
    });

    test('trop volumineux -> tooLarge', () {
      final big = Uint8List(CvImportPolicy.maxBytes + 1);
      big.setAll(0, [0x25, 0x50, 0x44, 0x46]);
      expect(CvImportPolicy.validate('cv.pdf', big), CvImportError.tooLarge);
    });

    test('extension insensible a la casse', () {
      expect(CvImportPolicy.validate('CV.PDF', pdfBytes), isNull);
    });
  });

  group('ImportCvUseCase (#249 D1)', () {
    test('fichier invalide -> ValidationException SANS appel gateway', () async {
      var called = false;
      final useCase = ImportCvUseCase((bytes, name) async {
        called = true;
        return Cv(titre: 'x');
      });

      final r = await useCase
          .call(CvImportFile(filename: 'cv.exe', bytes: pdfBytes));

      expect(r, isA<Failure<Cv>>());
      final failure = r as Failure<Cv>;
      expect(failure.exception, isA<ValidationException>());
      expect(failure.exception.code, CvImportError.invalidExtension.name);
      expect(called, isFalse, reason: 'pas d appel reseau si invalide');
    });

    test('fichier valide -> delegue et Result.success', () async {
      final useCase =
          ImportCvUseCase((bytes, name) async => Cv(id: 7, titre: 'Importe'));

      final r = await useCase
          .call(CvImportFile(filename: 'cv.pdf', bytes: pdfBytes));

      expect((r as Success).data.id, 7);
    });

    test('erreur gateway -> Result.failure (pas de throw)', () async {
      final useCase = ImportCvUseCase(
          (bytes, name) async => throw const NetworkException());

      final r = await useCase
          .call(CvImportFile(filename: 'cv.pdf', bytes: pdfBytes));

      expect(r, isA<Failure<Cv>>());
      expect((r as Failure<Cv>).exception, isA<NetworkException>());
    });
  });
}
