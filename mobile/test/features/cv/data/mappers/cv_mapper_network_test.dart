import 'dart:convert';
import 'dart:io';

import 'package:cv_mobile/features/cv/data/mappers/cv_mapper.dart';
import 'package:cv_mobile/features/cv/domain/entities/cv.dart';
import 'package:cv_mobile/features/cv/domain/value_objects/cv_id.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fixture(String name) => jsonDecode(
      File('test/features/cv/fixtures/$name').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  const mapper = CvMapper();

  group('fromNetworkJson — fixture complete', () {
    late CvEntity cv;
    setUp(() => cv = mapper.fromNetworkJson(_fixture('cv_network_full.json')));

    test('champs racine et id', () {
      expect(cv.id, const CvId(12));
      expect(cv.titre, 'Développeur Full-Stack');
      expect(cv.viewCount, 42);
      expect(cv.downloadCount, 7);
      expect(cv.variantCount, 2);
    });

    test('divergence de cle publicToken -> shareToken', () {
      expect(cv.shareToken, 'tok-abc-123');
    });

    test('publicEnabled lu tel quel', () {
      expect(cv.publicEnabled, isTrue);
      expect(cv.publicDownloadsEnabled, isTrue);
      expect(cv.publicContactEnabled, isFalse);
    });

    test('sections et style', () {
      expect(cv.experiences.single.poste, 'Développeur');
      expect(cv.experiences.single.actuel, isTrue);
      expect(cv.skills.single.nom, 'Flutter');
      expect(cv.style.templateId, 'ats');
      expect(cv.style.primaryColorArgb, 4278224787);
    });

    test('dates ISO completes parsees', () {
      expect(cv.createdAt, isNotNull);
      expect(cv.updatedAt, isNotNull);
    });
  });

  group('fromNetworkJson — publicEnabled deduit', () {
    test('absent + publicToken present => true', () {
      final cv = mapper.fromNetworkJson({
        'titre': 'T',
        'publicToken': 'abc',
      });
      expect(cv.publicEnabled, isTrue);
    });

    test('absent + publicToken absent => false', () {
      final cv = mapper.fromNetworkJson({'titre': 'T'});
      expect(cv.publicEnabled, isFalse);
      expect(cv.shareToken, isNull);
    });
  });

  group('fromNetworkJson — robustesse', () {
    test('fixture partielle : listes nulles => vides, personalInfo null', () {
      final cv = mapper.fromNetworkJson(_fixture('cv_network_partial.json'));
      expect(cv.personalInfo, isNull);
      expect(cv.experiences, isEmpty);
      expect(cv.skills, hasLength(1));
    });

    test('dates invalides => null, actuel non-bool => false', () {
      final cv = mapper.fromNetworkJson(_fixture('cv_network_invalid_dates.json'));
      final exp = cv.experiences.single;
      expect(exp.dateDebut, isNull);
      expect(exp.dateFin, isNull);
      expect(exp.actuel, isFalse);
      expect(cv.certifications.single.dateObtention, isNull);
    });

    test('titre absent => chaine vide (jamais de throw)', () {
      final cv = mapper.fromNetworkJson(const {});
      expect(cv.titre, '');
    });
  });

  group('toNetworkJson — format minimal (contrat backend)', () {
    test('emet uniquement les cles attendues par le serveur', () {
      final cv = mapper.fromNetworkJson(_fixture('cv_network_full.json'));
      final json = mapper.toNetworkJson(cv);
      expect(
        json.keys.toSet(),
        {
          'id',
          'titre',
          'personalInfo',
          'educations',
          'experiences',
          'skills',
          'languages',
          'certifications',
          'projects',
          'style',
        },
      );
    });

    test('n emet PAS les metadonnees serveur (viewCount, publicToken, dates)',
        () {
      final cv = mapper.fromNetworkJson(_fixture('cv_network_full.json'));
      final json = mapper.toNetworkJson(cv);
      for (final forbidden in const [
        'viewCount',
        'publicToken',
        'shareToken',
        'downloadCount',
        'shareCount',
        'createdAt',
        'updatedAt',
        'varianteLabel',
        'parentCvId',
      ]) {
        expect(json.containsKey(forbidden), isFalse,
            reason: '$forbidden ne doit pas etre envoye au serveur');
      }
    });

    test('id omis quand le CV n est pas persiste', () {
      final cv = CvEntity(titre: 'Nouveau');
      expect(mapper.toNetworkJson(cv).containsKey('id'), isFalse);
    });

    test('style serialise en int ARGB', () {
      final cv = mapper.fromNetworkJson(_fixture('cv_network_full.json'));
      final style = mapper.toNetworkJson(cv)['style'] as Map<String, dynamic>;
      expect(style['primaryColor'], 4278224787);
      expect(style['templateId'], 'ats');
    });
  });
}
