import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/services/connectivity_service.dart';

class MockCvRepository extends Mock implements CvRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

Cv _fakeCv({int id = 1, String titre = 'Mon CV'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void main() {
  late MockCvRepository mockRepo;
  late MockConnectivityService mockConnectivity;
  late StreamController<bool> connectivityCtrl;

  setUp(() {
    mockRepo = MockCvRepository();
    mockConnectivity = MockConnectivityService();
    connectivityCtrl = StreamController<bool>.broadcast();
    registerFallbackValue(_fakeCv());

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityCtrl.stream);
  });

  tearDown(() => connectivityCtrl.close());

  CvProvider buildProvider() =>
      CvProvider(repository: mockRepo, connectivity: mockConnectivity);

  group('CvProvider', () {
    test('etat initial : liste vide, pas de chargement', () {
      final provider = buildProvider();
      expect(provider.cvs, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.currentCv, null);
      expect(provider.isOffline, false);
    });

    test('loadCvs succes : peuple la liste', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'CV 2')];
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async => Result.success(cvs));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs.length, 2);
      expect(provider.cvs[0].titre, 'Mon CV');
      expect(provider.isLoading, false);
    });

    test('loadCvs echec : error defini, liste reste vide', () async {
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Erreur reseau')));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs, isEmpty);
      expect(provider.error, 'Erreur reseau');
      expect(provider.isLoading, false);
    });

    test('loadCvById succes : currentCv defini', () async {
      final cv = _fakeCv(id: 42, titre: 'CV Detail');
      when(() => mockRepo.getCvById(42)).thenAnswer((_) async => Result.success(cv));

      final provider = buildProvider();
      await provider.loadCvById(42);

      expect(provider.currentCv?.id, 42);
      expect(provider.currentCv?.titre, 'CV Detail');
    });

    test('createCv succes : ajoute a la liste', () async {
      final newCv = _fakeCv(id: 10, titre: 'Nouveau CV');
      when(() => mockRepo.createCv(any())).thenAnswer((_) async => Result.success(newCv));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv(titre: 'Nouveau CV'));

      expect(result, true);
      expect(provider.cvs.length, 1);
      expect(provider.cvs.first.id, 10);
    });

    test('createCv echec : retourne false, error defini', () async {
      when(() => mockRepo.createCv(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Creation impossible')));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv());

      expect(result, false);
      expect(provider.error, 'Creation impossible');
    });

    test('updateCv succes : met a jour la liste', () async {
      final original = _fakeCv(id: 5, titre: 'Ancien titre');
      final updated = _fakeCv(id: 5, titre: 'Nouveau titre');
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async => Result.success([original]));
      when(() => mockRepo.updateCv(5, any())).thenAnswer((_) async => Result.success(updated));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.updateCv(5, updated);

      expect(result, true);
      expect(provider.cvs.first.titre, 'Nouveau titre');
    });

    test('deleteCv succes : retire de la liste', () async {
      final cv = _fakeCv(id: 3);
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async => Result.success([cv]));
      when(() => mockRepo.deleteCv(3)).thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();
      await provider.loadCvs();
      expect(provider.cvs.length, 1);

      final result = await provider.deleteCv(3);
      expect(result, true);
      expect(provider.cvs, isEmpty);
    });

    test('deleteCv echec : retourne false', () async {
      when(() => mockRepo.deleteCv(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Suppression impossible')));

      final provider = buildProvider();
      final result = await provider.deleteCv(99);

      expect(result, false);
      expect(provider.error, 'Suppression impossible');
    });

    test('duplicateCv succes : ajoute la copie a la liste', () async {
      final original = _fakeCv(id: 5, titre: 'Mon CV');
      final copy = _fakeCv(id: 6, titre: 'Copie de Mon CV');
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async => Result.success([original]));
      when(() => mockRepo.duplicateCv(5)).thenAnswer((_) async => Result.success(copy));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.duplicateCv(5);

      expect(result, true);
      expect(provider.cvs.length, 2);
      expect(provider.cvs.last.titre, 'Copie de Mon CV');
    });

    test('duplicateCv echec : retourne false', () async {
      when(() => mockRepo.duplicateCv(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Duplication impossible')));

      final provider = buildProvider();
      final result = await provider.duplicateCv(99);

      expect(result, false);
      expect(provider.error, 'Duplication impossible');
    });

    test('isOffline passe a true quand connectivite perdue', () async {
      final provider = buildProvider();
      expect(provider.isOffline, false);

      connectivityCtrl.add(false);
      await Future.microtask(() {});

      expect(provider.isOffline, true);
    });

    test('isOffline repasse a false quand connectivite retrouvee', () async {
      when(() => mockRepo.getAllCvs()).thenAnswer((_) async => const Result.success([]));

      final provider = buildProvider();
      connectivityCtrl.add(false);
      await Future.microtask(() {});
      expect(provider.isOffline, true);

      connectivityCtrl.add(true);
      await Future.microtask(() {});
      expect(provider.isOffline, false);
    });
  });
}
