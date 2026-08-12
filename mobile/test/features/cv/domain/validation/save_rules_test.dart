import 'package:cv_mobile/features/cv/domain/validation/rules/save_rules.dart';
import 'package:cv_mobile/features/cv/domain/validation/validation_code.dart';
import 'package:cv_mobile/features/cv/domain/validation/validation_result.dart';
import 'package:cv_mobile/features/cv/domain/entities/cv.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/features/cv/domain/entities/personal_info.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rules = CvSaveRules();

  ValidationMessage? firstError(CvEntity cv) =>
      ValidationOutcome(rules.evaluate(cv)).firstError;

  CvEntity valid() => CvEntity(
        titre: 'Dev Flutter',
        personalInfo: const PersonalInfo(
          prenom: 'Issouf',
          nom: 'Ouedraogo',
          email: 'a@b.co',
        ),
      );

  group('CvSaveRules - validation bloquante (#241, remplace validateForSave)', () {
    test('CV minimal valide : aucune erreur', () {
      expect(firstError(valid()), isNull);
    });

    test('titre vide -> cvTitleRequired en premier', () {
      final cv = valid().copyWith(titre: '');
      expect(firstError(cv)?.code, ValidationCode.cvTitleRequired);
    });

    test('personalInfo null -> personalInfoIncomplete', () {
      final cv = CvEntity(titre: 'X', personalInfo: null);
      expect(firstError(cv)?.code, ValidationCode.personalInfoIncomplete);
    });

    test('email invalide -> invalidEmail', () {
      final cv = CvEntity(
        titre: 'X',
        personalInfo: const PersonalInfo(
            prenom: 'A', nom: 'B', email: 'pas-un-email'),
      );
      expect(firstError(cv)?.code, ValidationCode.invalidEmail);
    });

    test('experience sans poste -> requiredFieldMissing (section experiences)',
        () {
      final cv = valid().copyWith(experiences: [
        const Experience(poste: '', entreprise: 'ACME'),
      ]);
      final err = firstError(cv);
      expect(err?.code, ValidationCode.requiredFieldMissing);
      expect(err?.section, 'experiences');
      expect(err?.params['field'], 'jobTitle');
    });

    test('experience date fin avant debut -> endBeforeStart', () {
      final cv = valid().copyWith(experiences: [
        Experience(
          poste: 'Dev',
          entreprise: 'ACME',
          dateDebut: DateTime(2024, 6),
          dateFin: DateTime(2024, 1),
        ),
      ]);
      expect(firstError(cv)?.code, ValidationCode.endBeforeStart);
    });

    test('niveau de competence hors bornes -> skillLevelOutOfRange', () {
      final cv = valid().copyWith(skills: [
        const Skill(nom: 'Java', niveau: 9),
      ]);
      expect(firstError(cv)?.code, ValidationCode.skillLevelOutOfRange);
    });

    test('ordre : le titre prime sur une erreur d experience', () {
      final cv = valid().copyWith(
        titre: '',
        experiences: [const Experience(poste: '')],
      );
      // Le premier probleme rencontre reste le titre (ordre preserve).
      expect(firstError(cv)?.code, ValidationCode.cvTitleRequired);
    });
  });
}
