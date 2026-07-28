import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/data/mappers/cv_mapper.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/repositories/cached_cv_repository.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';

class MockCvRepository extends Mock implements CvRepository {}

const _mapper = CvMapper();

Cv _fakeCv({int id = 1, String titre = 'Mon CV'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

/// Serialise une liste de CV dans le format de cache versionne attendu par
/// [CachedCvRepository].
String _cacheBlob(List<Cv> cvs) =>
    _mapper.toCacheJson(cvs.map((c) => c.entity).toList());

/// Relit le cache tel que le repository le rechargerait (blob valide attendu).
List<Cv> _readCache(SharedPreferences prefs) =>
    (_mapper.fromCacheJson(prefs.getString('cached_cvs')!) ?? const [])
        .map(Cv.fromEntity)
        .toList();

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
    test('retourne les CVs du reseau et les met en cache', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'CV 2')];
      when(() => mockRemote.getAllCvs())
          .thenAnswer((_) async => Result.success(cvs));

      final repo = buildRepo();
      final result = await repo.getAllCvs();

      expect(result.isSuccess, true);
      expect((result as Success<List<Cv>>).data.length, 2);
      expect(prefs.getString('cached_cvs'), isNotNull);
    });

    test('retourne le cache si le reseau echoue', () async {
      await prefs.setString(
        'cached_cvs',
        _cacheBlob([_fakeCv(id: 99, titre: 'CV Cached')]),
      );
      when(() => mockRemote.getAllCvs()).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Offline')));

      final repo = buildRepo();
      final result = await repo.getAllCvs();

      expect(result.isSuccess, true);
      final data = (result as Success<List<Cv>>).data;
      expect(data.length, 1);
      expect(data.first.titre, 'CV Cached');
    });

    test('propage l\'erreur si reseau echoue et cache vide', () async {
      when(() => mockRemote.getAllCvs()).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Offline')));

      final repo = buildRepo();
      final result = await repo.getAllCvs();

      expect(result.isFailure, true);
    });

    test('propage l\'erreur reseau si le cache est corrompu (pas de liste vide)',
        () async {
      // Un cache illisible ne doit pas masquer l'echec reseau derriere un
      // Result.success([]) : l'erreur reseau doit remonter a l'appelant.
      await prefs.setString('cached_cvs', '{{ blob corrompu');
      when(() => mockRemote.getAllCvs()).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Offline')));

      final result = await buildRepo().getAllCvs();

      expect(result.isFailure, true);
    });

    test('sert le cache vide legitime (distinct du cache corrompu)', () async {
      // Cache present et valide mais vide : on sert bien [] en fallback.
      await prefs.setString('cached_cvs', _cacheBlob([]));
      when(() => mockRemote.getAllCvs()).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Offline')));

      final result = await buildRepo().getAllCvs();

      expect(result.isSuccess, true);
      expect((result as Success<List<Cv>>).data, isEmpty);
    });
  });

  group('CachedCvRepository.createCv', () {
    test('ajoute le nouveau CV au cache apres creation', () async {
      await prefs.setString('cached_cvs', _cacheBlob([_fakeCv(id: 1)]));
      final newCv = _fakeCv(id: 2, titre: 'Nouveau');
      when(() => mockRemote.createCv(any()))
          .thenAnswer((_) async => Result.success(newCv));

      final repo = buildRepo();
      await repo.createCv(_fakeCv(titre: 'Nouveau'));

      final list = _readCache(prefs);
      expect(list.length, 2);
      expect(list.last.titre, 'Nouveau');
    });
  });

  group('CachedCvRepository.deleteCv', () {
    test('retire le CV du cache apres suppression', () async {
      await prefs.setString(
        'cached_cvs',
        _cacheBlob([_fakeCv(id: 1), _fakeCv(id: 2, titre: 'A supprimer')]),
      );
      when(() => mockRemote.deleteCv(2))
          .thenAnswer((_) async => const Result.success(null));

      final repo = buildRepo();
      await repo.deleteCv(2);

      final list = _readCache(prefs);
      expect(list.length, 1);
      expect(list.first.id, 1);
    });
  });

  group('CachedCvRepository.updateCv', () {
    test('met a jour le CV dans le cache', () async {
      await prefs.setString(
        'cached_cvs',
        _cacheBlob([_fakeCv(id: 5, titre: 'Ancien')]),
      );
      final updated = _fakeCv(id: 5, titre: 'Nouveau');
      when(() => mockRemote.updateCv(5, any()))
          .thenAnswer((_) async => Result.success(updated));

      final repo = buildRepo();
      await repo.updateCv(5, updated);

      final list = _readCache(prefs);
      expect(list.first.titre, 'Nouveau');
    });
  });
}
