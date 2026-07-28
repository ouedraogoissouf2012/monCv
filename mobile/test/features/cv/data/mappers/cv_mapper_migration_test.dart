import 'dart:io';

import 'package:cv_mobile/features/cv/data/mappers/cv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

String _raw(String name) =>
    File('test/features/cv/fixtures/$name').readAsStringSync();

void main() {
  const mapper = CvMapper();

  group('migration & robustesse du cache', () {
    test('format legacy (liste brute) => migre en V0->V1', () {
      final cvs = mapper.fromCacheJson(_raw('cv_cache_legacy_list.json'));
      expect(cvs, hasLength(1));
      expect(cvs!.single.titre, 'Ancien cache format liste');
      expect(cvs.single.personalInfo?.nom, 'Legacy');
      expect(cvs.single.experiences.single.poste, 'Dev');
    });

    test('version inconnue (future) => null (illisible, pas vide)', () {
      // null distingue "illisible" de "legitimement vide" pour ne pas masquer
      // une erreur reseau derriere une liste vide cote repository.
      expect(mapper.fromCacheJson(_raw('cv_cache_unknown_version.json')),
          isNull);
    });

    test('JSON corrompu => null', () {
      expect(mapper.fromCacheJson('{{ ceci n est pas du json'), isNull);
    });

    test('chaine vide => null', () {
      expect(mapper.fromCacheJson(''), isNull);
    });

    test('forme inattendue (objet sans data) => null', () {
      expect(mapper.fromCacheJson('{"autre": 1}'), isNull);
    });

    test('cache legitimement vide => liste vide (distinct de illisible)', () {
      expect(mapper.fromCacheJson('{"schemaVersion": 1, "data": []}'), isEmpty);
      expect(mapper.fromCacheJson('[]'), isEmpty);
    });

    test('un item corrompu dans data n annule pas les items valides', () {
      const mixed =
          '{"schemaVersion": 1, "data": [{"titre": "ok"}, 42, "pas un objet"]}';
      final cvs = mapper.fromCacheJson(mixed);
      expect(cvs, hasLength(1));
      expect(cvs!.single.titre, 'ok');
    });
  });
}
