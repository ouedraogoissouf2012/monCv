import 'package:cv_mobile/features/cv/domain/entities/cv.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:cv_mobile/features/cv/domain/value_objects/cv_id.dart';
import 'package:cv_mobile/features/cv/domain/value_objects/cv_style_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvEntity valeurs par defaut', () {
    test('listes vides et style fallback', () {
      final cv = CvEntity(titre: 'Test');
      expect(cv.educations, isEmpty);
      expect(cv.experiences, isEmpty);
      expect(cv.viewCount, 0);
      expect(cv.publicEnabled, isFalse);
      expect(cv.style, CvStyleRef.fallback);
    });
  });

  group('CvEntity.isVariante', () {
    test('vrai quand varianteLabel present', () {
      final cv = CvEntity(titre: 'T', varianteLabel: 'Dev Backend');
      expect(cv.isVariante, isTrue);
    });

    test('faux quand varianteLabel absent', () {
      final cv = CvEntity(titre: 'T');
      expect(cv.isVariante, isFalse);
    });
  });

  group('CvEntity immutabilite des collections', () {
    test('la liste exposee est non modifiable', () {
      final cv = CvEntity(
        titre: 'T',
        experiences: [const Experience(poste: 'Dev')],
      );
      expect(() => cv.experiences.add(const Experience()),
          throwsUnsupportedError);
    });

    test('muter la liste source apres construction n affecte pas l entite', () {
      final source = [const Skill(nom: 'Flutter')];
      final cv = CvEntity(titre: 'T', skills: source);
      source.add(const Skill(nom: 'Dart'));
      expect(cv.skills, hasLength(1)); // copie defensive
    });
  });

  group('CvEntity.copyWith conserver / remplacer / effacer', () {
    final base = CvEntity(
      id: const CvId(7),
      titre: 'Original',
      varianteLabel: 'Variante A',
      shareToken: 'tok123',
      parentCvId: 3,
      viewCount: 42,
      createdAt: DateTime(2026, 1, 1),
    );

    test('sans argument, conserve tout (y compris metadonnees)', () {
      final copy = base.copyWith();
      expect(copy.id, const CvId(7));
      expect(copy.titre, 'Original');
      expect(copy.varianteLabel, 'Variante A');
      expect(copy.shareToken, 'tok123');
      expect(copy.parentCvId, 3);
      expect(copy.viewCount, 42);
      expect(copy.createdAt, DateTime(2026, 1, 1));
    });

    test('remplace un champ non nullable', () {
      final copy = base.copyWith(titre: 'Nouveau');
      expect(copy.titre, 'Nouveau');
      expect(copy.varianteLabel, 'Variante A'); // le reste conserve
    });

    test('efface varianteLabel avec null (de-variante un CV)', () {
      final copy = base.copyWith(varianteLabel: null);
      expect(copy.varianteLabel, isNull);
      expect(copy.isVariante, isFalse);
      // le reste intact
      expect(copy.shareToken, 'tok123');
    });

    test('efface shareToken avec null sans toucher les autres', () {
      final copy = base.copyWith(shareToken: null);
      expect(copy.shareToken, isNull);
      expect(copy.varianteLabel, 'Variante A');
    });

    test('createdAt et updatedAt sont desormais parametrables', () {
      final copy = base.copyWith(
        updatedAt: DateTime(2026, 6, 1),
      );
      expect(copy.updatedAt, DateTime(2026, 6, 1));
      expect(copy.createdAt, DateTime(2026, 1, 1)); // conserve

      final erased = base.copyWith(createdAt: null);
      expect(erased.createdAt, isNull);
    });

    test('efface l id (repasse en brouillon non persiste)', () {
      final copy = base.copyWith(id: null);
      expect(copy.id, isNull);
    });

    test('remplace une collection', () {
      final copy = base.copyWith(skills: [const Skill(nom: 'Go')]);
      expect(copy.skills, hasLength(1));
      expect(copy.skills.first.nom, 'Go');
    });
  });

  group('CvEntity egalite', () {
    test('structurelle sur les champs et collections', () {
      final a = CvEntity(titre: 'T', skills: [const Skill(nom: 'Flutter')]);
      final b = CvEntity(titre: 'T', skills: [const Skill(nom: 'Flutter')]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('une difference de collection casse l egalite', () {
      final a = CvEntity(titre: 'T', skills: [const Skill(nom: 'Flutter')]);
      final b = CvEntity(titre: 'T', skills: [const Skill(nom: 'Dart')]);
      expect(a == b, isFalse);
    });
  });
}
