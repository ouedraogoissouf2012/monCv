import 'dart:convert';

import 'package:cv_mobile/features/cv/data/mappers/cv_mapper.dart';
import 'package:cv_mobile/features/cv/domain/entities/certification.dart';
import 'package:cv_mobile/features/cv/domain/entities/cv.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/features/cv/domain/entities/personal_info.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:cv_mobile/features/cv/domain/value_objects/cv_id.dart';
import 'package:cv_mobile/features/cv/domain/value_objects/cv_style_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CvMapper();

  CvEntity richCv() => CvEntity(
        id: const CvId(5),
        titre: 'Complet',
        personalInfo: const PersonalInfo(nom: 'Doe', email: 'd@e.c'),
        experiences: [
          Experience(poste: 'Dev', dateDebut: DateTime(2020, 1, 15)),
        ],
        skills: [const Skill(nom: 'Flutter', niveau: 4)],
        certifications: [
          Certification(nom: 'AWS', dateObtention: DateTime(2021, 3, 10)),
        ],
        viewCount: 42,
        parentCvId: 3,
        varianteLabel: 'Variante A',
        variantCount: 2,
        shareToken: 'tok-1',
        publicEnabled: true,
        publicDownloadsEnabled: true,
        publicContactEnabled: true,
        downloadCount: 7,
        shareCount: 9,
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 6, 20),
        style: const CvStyleRef(
          templateId: 'creatif',
          fontFamily: 'Poppins',
          primaryColorArgb: 0xFFEC4899,
        ),
      );

  group('round-trip cache SANS perte', () {
    test('tous les champs preserves apres toCacheJson/fromCacheJson', () {
      final original = richCv();
      final restored = mapper.fromCacheJson(mapper.toCacheJson([original]));
      expect(restored, hasLength(1));
      // Egalite structurelle complete de l'entite.
      expect(restored.single, original);
    });

    test('les metadonnees perdues par le format reseau sont conservees', () {
      final restored =
          mapper.fromCacheJson(mapper.toCacheJson([richCv()])).single;
      expect(restored.viewCount, 42);
      expect(restored.shareToken, 'tok-1');
      expect(restored.downloadCount, 7);
      expect(restored.shareCount, 9);
      expect(restored.varianteLabel, 'Variante A');
      expect(restored.parentCvId, 3);
      expect(restored.createdAt, DateTime(2026, 1, 5));
      expect(restored.updatedAt, DateTime(2026, 6, 20));
      expect(restored.style.templateId, 'creatif');
    });

    test('liste vide round-trip', () {
      expect(mapper.fromCacheJson(mapper.toCacheJson([])), isEmpty);
    });
  });

  group('enveloppe versionnee', () {
    test('toCacheJson emet schemaVersion courant + data', () {
      final decoded =
          jsonDecode(mapper.toCacheJson([richCv()])) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], kCvCacheSchemaVersion);
      expect(decoded['data'], isA<List<dynamic>>());
    });
  });

  group('helpers single (file de sync offline)', () {
    test('round-trip single sans perte', () {
      final original = richCv();
      final restored = mapper.cvFromCacheString(
        mapper.cvToCacheString(original),
      );
      expect(restored, original);
    });

    test('chaine corrompue => null (pas de throw)', () {
      expect(mapper.cvFromCacheString('{{ pas du json'), isNull);
    });
  });
}
