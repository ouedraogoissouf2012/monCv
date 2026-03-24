import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

Cv _fakeCv({int id = 1, String titre = 'Mon CV'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
    registerFallbackValue(_fakeCv());
  });

  CvProvider buildProvider() => CvProvider(apiService: mockApi);

  group('CvProvider', () {
    test('état initial : liste vide, pas de chargement', () {
      final provider = buildProvider();
      expect(provider.cvs, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.currentCv, null);
    });

    test('loadCvs succès : peuple la liste', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'CV 2')];
      when(() => mockApi.getAllCvs()).thenAnswer((_) async => cvs);

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs.length, 2);
      expect(provider.cvs[0].titre, 'Mon CV');
      expect(provider.isLoading, false);
    });

    test('loadCvs échec : error défini, liste reste vide', () async {
      when(() => mockApi.getAllCvs()).thenThrow(Exception('Erreur réseau'));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs, isEmpty);
      expect(provider.error, 'Erreur réseau');
      expect(provider.isLoading, false);
    });

    test('loadCvById succès : currentCv défini', () async {
      final cv = _fakeCv(id: 42, titre: 'CV Détail');
      when(() => mockApi.getCvById(42)).thenAnswer((_) async => cv);

      final provider = buildProvider();
      await provider.loadCvById(42);

      expect(provider.currentCv?.id, 42);
      expect(provider.currentCv?.titre, 'CV Détail');
    });

    test('createCv succès : ajoute à la liste', () async {
      final newCv = _fakeCv(id: 10, titre: 'Nouveau CV');
      when(() => mockApi.createCv(any())).thenAnswer((_) async => newCv);

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv(titre: 'Nouveau CV'));

      expect(result, true);
      expect(provider.cvs.length, 1);
      expect(provider.cvs.first.id, 10);
    });

    test('createCv échec : retourne false, error défini', () async {
      when(() => mockApi.createCv(any())).thenThrow(Exception('Création impossible'));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv());

      expect(result, false);
      expect(provider.error, 'Création impossible');
    });

    test('updateCv succès : met à jour la liste', () async {
      final original = _fakeCv(id: 5, titre: 'Ancien titre');
      final updated = _fakeCv(id: 5, titre: 'Nouveau titre');
      when(() => mockApi.getAllCvs()).thenAnswer((_) async => [original]);
      when(() => mockApi.updateCv(5, any())).thenAnswer((_) async => updated);

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.updateCv(5, updated);

      expect(result, true);
      expect(provider.cvs.first.titre, 'Nouveau titre');
    });

    test('deleteCv succès : retire de la liste', () async {
      final cv = _fakeCv(id: 3);
      when(() => mockApi.getAllCvs()).thenAnswer((_) async => [cv]);
      when(() => mockApi.deleteCv(3)).thenAnswer((_) async {});

      final provider = buildProvider();
      await provider.loadCvs();
      expect(provider.cvs.length, 1);

      final result = await provider.deleteCv(3);
      expect(result, true);
      expect(provider.cvs, isEmpty);
    });

    test('deleteCv échec : retourne false', () async {
      when(() => mockApi.deleteCv(any())).thenThrow(Exception('Suppression impossible'));

      final provider = buildProvider();
      final result = await provider.deleteCv(99);

      expect(result, false);
      expect(provider.error, 'Suppression impossible');
    });
  });
}
