import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/cv_list/application/import_cv.dart';
import 'package:cv_mobile/features/cv_list/presentation/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';

/// Fichier PDF valide (extension + magic bytes `%PDF` + taille non nulle) : passe
/// la validation locale de [CvImportPolicy] et atteint la gateway.
CvImportFile _validPdf() => CvImportFile(
      filename: 'cv.pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
    );

/// Fichier a extension refusee : rejete AVANT tout appel reseau.
CvImportFile _badExtension() => CvImportFile(
      filename: 'cv.txt',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
    );

Cv _fakeCv() => Cv(
      id: 42,
      titre: 'CV importe',
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

CvListController _controller({
  required PickImportFile pickFile,
  required ImportCvGateway gateway,
  Future<bool> Function()? reload,
  Future<bool> Function(int)? deleteCv,
  Future<bool> Function(int)? duplicateCv,
}) =>
    CvListController(
      importCv: ImportCvUseCase(gateway),
      pickFile: pickFile,
      reload: reload ?? () async => true,
      deleteCv: deleteCv ?? (_) async => true,
      duplicateCv: duplicateCv ?? (_) async => true,
    );

void main() {
  group('CvListController.importFromFile', () {
    test('annulation (aucun fichier) → null, pas d\'appel gateway', () async {
      var gatewayCalled = false;
      final controller = _controller(
        pickFile: () async => null,
        gateway: (bytes, filename) async {
          gatewayCalled = true;
          return _fakeCv();
        },
      );

      final outcome = await controller.importFromFile();

      expect(outcome, isNull);
      expect(gatewayCalled, isFalse);
      expect(controller.importing, isFalse);
      expect(controller.importError, isNull);
    });

    test('fichier valide → success, liste rechargee', () async {
      var reloadCalled = false;
      final controller = _controller(
        pickFile: () async => _validPdf(),
        gateway: (bytes, filename) async => _fakeCv(),
        reload: () async {
          reloadCalled = true;
          return true;
        },
      );

      final outcome = await controller.importFromFile();

      expect(outcome, CvListActionOutcome.success);
      expect(reloadCalled, isTrue);
      expect(controller.importing, isFalse);
      expect(controller.importError, isNull);
      expect(controller.importedTitle, 'CV importe');
    });

    test('extension refusee → invalidInput, code de validation, sans reseau',
        () async {
      var gatewayCalled = false;
      var reloadCalled = false;
      final controller = _controller(
        pickFile: () async => _badExtension(),
        gateway: (bytes, filename) async {
          gatewayCalled = true;
          return _fakeCv();
        },
        reload: () async {
          reloadCalled = true;
          return true;
        },
      );

      final outcome = await controller.importFromFile();

      expect(outcome, CvListActionOutcome.invalidInput);
      expect(controller.importError, 'invalidExtension');
      expect(gatewayCalled, isFalse);
      expect(reloadCalled, isFalse);
      expect(controller.importing, isFalse);
    });

    test('echec reseau (gateway leve) → failure, erreur renseignee', () async {
      final controller = _controller(
        pickFile: () async => _validPdf(),
        gateway: (bytes, filename) async => throw Exception('boom'),
      );

      final outcome = await controller.importFromFile();

      expect(outcome, CvListActionOutcome.failure);
      expect(controller.importError, isNotNull);
      expect(controller.importing, isFalse);
    });

    test('importing passe a true pendant l\'import puis false', () async {
      final states = <bool>[];
      late final CvListController controller;
      controller = _controller(
        pickFile: () async => _validPdf(),
        gateway: (bytes, filename) async {
          states.add(controller.importing);
          return _fakeCv();
        },
      );

      await controller.importFromFile();

      // Vrai pendant l'appel gateway, faux une fois termine.
      expect(states, [true]);
      expect(controller.importing, isFalse);
    });

    test('notifie les listeners au demarrage et a la fin', () async {
      var notifications = 0;
      final controller = _controller(
        pickFile: () async => _validPdf(),
        gateway: (bytes, filename) async => _fakeCv(),
      );
      controller.addListener(() => notifications++);

      await controller.importFromFile();

      // notifyListeners au debut (importing=true) + a la fin (success).
      expect(notifications, greaterThanOrEqualTo(2));
    });
  });

  group('CvListController delegations', () {
    test('deleteCv delegue avec l\'id et retourne le resultat', () async {
      int? deletedId;
      final controller = _controller(
        pickFile: () async => null,
        gateway: (bytes, filename) async => _fakeCv(),
        deleteCv: (id) async {
          deletedId = id;
          return true;
        },
      );

      final ok = await controller.deleteCv(7);

      expect(ok, isTrue);
      expect(deletedId, 7);
    });

    test('duplicateCv delegue avec l\'id et propage l\'echec', () async {
      int? duplicatedId;
      final controller = _controller(
        pickFile: () async => null,
        gateway: (bytes, filename) async => _fakeCv(),
        duplicateCv: (id) async {
          duplicatedId = id;
          return false;
        },
      );

      final ok = await controller.duplicateCv(9);

      expect(ok, isFalse);
      expect(duplicatedId, 9);
    });
  });
}
