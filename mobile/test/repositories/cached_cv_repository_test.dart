import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/repositories/cached_cv_repository.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';

class MockCvRepository extends Mock implements CvRepository {}

Cv _fakeCv({int id = 1, String titre = 'Mon CV'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void main() {
  late MockCvRepository mockRemote;
  late SharedPreferences prefs;

  setUp(() async {
    mockRemote = MockCvRepository();
    registerFallbackValue(_fakeCv());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  CachedCvRepository buildRepo() =>
      CachedCvRepository(remote: mockRemote, prefs: prefs);

  group('CachedCvRepository.getAllCvs', () {
    test('retourne les CVs du réseau et les met en cache', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'CV 2')];
      when(() => mockRemote.getAllCvs()).thenAnswer((_) async => cvs);

      final repo = buildRepo();
      final result = await repo.getAllCvs();

      expect(result.length, 2);
      expect(prefs.getString('cached_cvs'), isNotNull);
    });

    test('retourne le cache si le réseau échoue', () async {
      final cached = [_fakeCv(id: 99, titre: 'CV Cached')];
      await prefs.setString(
        'cached_cvs',
        jsonEncode(cached.map((c) => c.toJson()).toList()),
      );
      when(() => mockRemote.getAllCvs()).thenThrow(Exception('Offline'));

      final repo = buildRepo();
      final result = await repo.getAllCvs();

      expect(result.length, 1);
      expect(result.first.titre, 'CV Cached');
    });

    test('propage l\'erreur si réseau échoue et cache vide', () async {
      when(() => mockRemote.getAllCvs()).thenThrow(Exception('Offline'));

      final repo = buildRepo();
      expect(() => repo.getAllCvs(), throwsException);
    });
  });

  group('CachedCvRepository.createCv', () {
    test('ajoute le nouveau CV au cache après création', () async {
      final existing = [_fakeCv(id: 1)];
      await prefs.setString(
        'cached_cvs',
        jsonEncode(existing.map((c) => c.toJson()).toList()),
      );
      final newCv = _fakeCv(id: 2, titre: 'Nouveau');
      when(() => mockRemote.createCv(any())).thenAnswer((_) async => newCv);

      final repo = buildRepo();
      await repo.createCv(_fakeCv(titre: 'Nouveau'));

      final raw = prefs.getString('cached_cvs')!;
      final list = (jsonDecode(raw) as List).map((e) => Cv.fromJson(e)).toList();
      expect(list.length, 2);
      expect(list.last.titre, 'Nouveau');
    });
  });

  group('CachedCvRepository.deleteCv', () {
    test('retire le CV du cache après suppression', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'À supprimer')];
      await prefs.setString(
        'cached_cvs',
        jsonEncode(cvs.map((c) => c.toJson()).toList()),
      );
      when(() => mockRemote.deleteCv(2)).thenAnswer((_) async {});

      final repo = buildRepo();
      await repo.deleteCv(2);

      final raw = prefs.getString('cached_cvs')!;
      final list = (jsonDecode(raw) as List).map((e) => Cv.fromJson(e)).toList();
      expect(list.length, 1);
      expect(list.first.id, 1);
    });
  });

  group('CachedCvRepository.updateCv', () {
    test('met à jour le CV dans le cache', () async {
      final cvs = [_fakeCv(id: 5, titre: 'Ancien')];
      await prefs.setString(
        'cached_cvs',
        jsonEncode(cvs.map((c) => c.toJson()).toList()),
      );
      final updated = _fakeCv(id: 5, titre: 'Nouveau');
      when(() => mockRemote.updateCv(5, any())).thenAnswer((_) async => updated);

      final repo = buildRepo();
      await repo.updateCv(5, updated);

      final raw = prefs.getString('cached_cvs')!;
      final list = (jsonDecode(raw) as List).map((e) => Cv.fromJson(e)).toList();
      expect(list.first.titre, 'Nouveau');
    });
  });
}
