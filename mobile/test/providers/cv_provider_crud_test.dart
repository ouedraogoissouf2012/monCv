import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/providers/cv_provider.dart';

import 'helpers/cv_provider_harness.dart';

/// Caracterise le CRUD de base de [CvProvider] : chargement, creation,
/// mise a jour, suppression, duplication, style, relecture IA et
/// transitions de connectivite. Decoupe depuis `cv_provider_test.dart`
/// (#234) sans changer les comportements.
void main() {
  late CvProviderHarness harness;

  setUp(() {
    harness = CvProviderHarness();
    harness.setUp();
  });

  tearDown(() => harness.tearDown());

  CvProvider buildProvider() => harness.buildProvider();

  group('CvProvider CRUD', () {
    test('etat initial : liste vide', () {
      final provider = buildProvider();
      expect(provider.cvs, isEmpty);
      expect(provider.isLoading, false);
    });

    test('loadCvs succes', () async {
      final cvs = [minimalCv(id: 1), minimalCv(id: 2, titre: 'CV 2')];
      when(() => harness.getAll(any()))
          .thenAnswer((_) async => Result.success(cvs));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs.length, 2);
    });

    test('loadCvs echec', () async {
      when(() => harness.getAll(any())).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Erreur reseau')));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs, isEmpty);
      expect(provider.error, 'Erreur reseau');
    });

    test('loadCvById succes', () async {
      final cv = minimalCv(id: 42, titre: 'CV Detail');
      when(() => harness.getById(42))
          .thenAnswer((_) async => Result.success(cv));

      final provider = buildProvider();
      await provider.loadCvById(42);

      expect(provider.currentCv?.id, 42);
    });

    test('createCv succes', () async {
      final newCv = minimalCv(id: 10, titre: 'Nouveau CV');
      when(() => harness.create(any()))
          .thenAnswer((_) async => Result.success(newCv));

      final provider = buildProvider();
      final result = await provider.createCv(minimalCv(titre: 'Nouveau CV'));

      expect(result, true);
      expect(provider.cvs.length, 1);
    });

    test('createCv echec', () async {
      when(() => harness.create(any())).thenAnswer((_) async =>
          const Result.failure(
              ServerException(message: 'Creation impossible')));

      final provider = buildProvider();
      final result = await provider.createCv(minimalCv());

      expect(result, false);
      expect(provider.error, 'Creation impossible');
    });

    test('updateCv succes', () async {
      final original = minimalCv(id: 5, titre: 'Ancien');
      final updated = minimalCv(id: 5, titre: 'Nouveau');
      when(() => harness.getAll(any()))
          .thenAnswer((_) async => Result.success([original]));
      when(() => harness.update(any()))
          .thenAnswer((_) async => Result.success(updated));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.updateCv(5, updated);

      expect(result, true);
      expect(provider.cvs.first.titre, 'Nouveau');
    });

    test('deleteCv succes', () async {
      final cv = minimalCv(id: 3);
      when(() => harness.getAll(any()))
          .thenAnswer((_) async => Result.success([cv]));
      when(() => harness.delete(3))
          .thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.deleteCv(3);

      expect(result, true);
      expect(provider.cvs, isEmpty);
    });

    test('deleteCv echec', () async {
      when(() => harness.delete(any())).thenAnswer((_) async =>
          const Result.failure(
              ServerException(message: 'Suppression impossible')));

      final provider = buildProvider();
      final result = await provider.deleteCv(99);

      expect(result, false);
      expect(provider.error, 'Suppression impossible');
    });

    test('duplicateCv succes', () async {
      final copy = minimalCv(id: 6, titre: 'Copie');
      when(() => harness.getAll(any()))
          .thenAnswer((_) async => Result.success([minimalCv(id: 5)]));
      when(() => harness.duplicate(5))
          .thenAnswer((_) async => Result.success(copy));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.duplicateCv(5);

      expect(result, true);
      expect(provider.cvs.length, 2);
    });

    test('updateCvStyle sauvegarde le style via le repository', () async {
      final cv = minimalCv(id: 7);
      when(() => harness.repository.updateCv(7, any()))
          .thenAnswer((invocation) async {
        return Result.success(invocation.positionalArguments[1] as Cv);
      });

      final provider = buildProvider();
      provider.setCurrentCv(cv);

      final result = await provider.updateCvStyle(7, sampleStyle);

      expect(result, true);
      expect(provider.currentCv?.style.templateId, 'classique');
      expect(provider.currentCv?.style.primaryColor.toARGB32(), 0xFF10B981);
      expect(provider.currentCv?.style.fontFamily, 'Lato');
      verify(() => harness.repository.updateCv(7, any())).called(1);
    });

    test('applyAiEnhancements applique la relecture sans perdre les niveaux',
        () async {
      final cv = aiReviewCv();
      when(() => harness.repository.updateCv(42, any()))
          .thenAnswer((invocation) async {
        return Result.success(invocation.positionalArguments[1] as Cv);
      });

      final provider = buildProvider()..setCurrentCv(cv);
      final result = await provider.applyAiEnhancements(42, aiReviewPayload());

      expect(result, true);
      expect(provider.currentCv?.personalInfo?.titrePoste, 'Community manager');
      expect(provider.currentCv?.experiences.first.poste, 'Community manager');
      expect(provider.currentCv?.educations.first.etablissement,
          'lycée municipal');
      expect(provider.currentCv?.skills.first.nom, 'Word');
      expect(provider.currentCv?.skills.first.niveau, 1);
      expect(provider.currentCv?.languages.first.langue, 'Français');
      expect(provider.currentCv?.certifications.first.organisme, 'Université');
      expect(provider.currentCv?.projects.first.technologies, 'Excel, Canva');
      verify(() => harness.repository.updateCv(42, any())).called(1);
    });

    test('connectivity offline', () async {
      final provider = buildProvider();
      harness.connectivityController.add(false);
      await Future.microtask(() {});
      expect(provider.isOffline, true);
    });

    test('connectivity restored', () async {
      when(() => harness.getAll(any()))
          .thenAnswer((_) async => const Result.success([]));

      final provider = buildProvider();
      harness.connectivityController.add(false);
      await Future.microtask(() {});
      harness.connectivityController.add(true);
      await Future.microtask(() {});
      expect(provider.isOffline, false);
    });
  });
}
