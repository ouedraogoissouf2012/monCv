import 'package:cv_mobile/features/cv/domain/validation/cv_validation_rules.dart';
import 'package:cv_mobile/features/cv/domain/validation/rules/personal_info_rules.dart';
import 'package:cv_mobile/features/cv/domain/validation/rules/section_rules.dart';
import 'package:cv_mobile/features/cv/domain/validation/validation_code.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Cv cvWith({
    PersonalInfo? info,
    List<Experience> experiences = const [],
    List<Education> educations = const [],
    List<Skill> skills = const [],
    List<Language> languages = const [],
    List<Certification> certifications = const [],
    List<Project> projects = const [],
  }) =>
      Cv(
        titre: 'CV',
        personalInfo: info,
        experiences: experiences,
        educations: educations,
        skills: skills,
        languages: languages,
        certifications: certifications,
        projects: projects,
      );

  Set<ValidationCode> codesOf(List messages) =>
      messages.map((m) => m.code as ValidationCode).toSet();

  group('PersonalInfoRule (#241)', () {
    test('personalInfo null -> personalInfoMissing (error)', () {
      final out = const PersonalInfoRule().evaluate(cvWith());
      expect(out.single.code, ValidationCode.personalInfoMissing);
      expect(out.single.isError, isTrue);
    });

    test('champs vides -> requiredFieldMissing par champ', () {
      final out = const PersonalInfoRule()
          .evaluate(cvWith(info: const PersonalInfo()));
      final fields = out
          .where((m) => m.code == ValidationCode.requiredFieldMissing)
          .map((m) => m.params['field'])
          .toSet();
      expect(fields, {'firstName', 'lastName', 'email'});
    });

    test('resume court -> summaryShort avec longueur en param', () {
      final out = const PersonalInfoRule().evaluate(cvWith(
          info: const PersonalInfo(
              prenom: 'A',
              nom: 'B',
              email: 'a@b.co',
              titrePoste: 'X',
              resumeProfessionnel: 'court')));
      final short =
          out.firstWhere((m) => m.code == ValidationCode.summaryShort);
      expect(short.params['length'], 5);
    });

    test('profil dev sans lien -> techLinkMissing', () {
      final out = const PersonalInfoRule().evaluate(cvWith(
          info: const PersonalInfo(
              prenom: 'A',
              nom: 'B',
              email: 'a@b.co',
              titrePoste: 'Developpeur',
              resumeProfessionnel:
                  'Un resume suffisamment long pour ne pas declencher summaryShort ici.')));
      expect(codesOf(out), contains(ValidationCode.techLinkMissing));
    });
  });

  group('ExperienceRule (#241)', () {
    test('aucune experience -> noExperience', () {
      final out = const ExperienceRule().evaluate(cvWith());
      expect(out.single.code, ValidationCode.noExperience);
    });

    test('date fin avant debut -> endBeforeStart (error)', () {
      final out = const ExperienceRule().evaluate(cvWith(experiences: [
        Experience(
          poste: 'Dev',
          description: 'Fait des choses avec 3 metriques.',
          dateDebut: DateTime(2024, 6),
          dateFin: DateTime(2024, 1),
        ),
      ]));
      final err = out.firstWhere((m) => m.isError);
      expect(err.code, ValidationCode.endBeforeStart);
    });

    test('description sans chiffre -> noMetric (warning)', () {
      final out = const ExperienceRule().evaluate(cvWith(experiences: const [
        Experience(poste: 'Dev', description: 'Description sans metrique.'),
      ]));
      expect(codesOf(out), contains(ValidationCode.noMetric));
    });

    test('description vide -> descriptionMissing (error)', () {
      final out = const ExperienceRule().evaluate(cvWith(experiences: const [
        Experience(poste: 'Dev', description: '   '),
      ]));
      expect(codesOf(out), contains(ValidationCode.descriptionMissing));
    });
  });

  group('SkillsRule (#241)', () {
    test('peu de competences -> fewSkills avec count', () {
      final out = const SkillsRule().evaluate(cvWith(skills: [
        const Skill(nom: 'Java'),
        const Skill(nom: 'Dart'),
      ]));
      final few = out.firstWhere((m) => m.code == ValidationCode.fewSkills);
      expect(few.params['count'], 2);
    });

    test('competence combinee (virgule) -> combinedSkills', () {
      final out = const SkillsRule().evaluate(cvWith(skills: [
        const Skill(nom: 'Java, Spring, Docker'),
      ]));
      expect(codesOf(out), contains(ValidationCode.combinedSkills));
    });
  });

  group('OverallContentRule (#241)', () {
    test('plus de 25 items -> tooMuchContent avec total', () {
      final out = const OverallContentRule().evaluate(cvWith(
        skills: List.generate(26, (i) => Skill(nom: 'S$i')),
      ));
      final over =
          out.firstWhere((m) => m.code == ValidationCode.tooMuchContent);
      expect(over.params['count'], 26);
    });

    test('25 items ou moins -> aucun message', () {
      final out = const OverallContentRule().evaluate(cvWith(
        skills: List.generate(10, (i) => Skill(nom: 'S$i')),
      ));
      expect(out, isEmpty);
    });
  });

  group('CvValidationRules - registre deterministe (#241)', () {
    test('CV vide : agrege les avertissements de plusieurs sections', () {
      final outcome =
          const CvValidationRules().evaluate(cvWith(info: const PersonalInfo()));
      // Doit contenir au moins : champs requis (identite), noExperience,
      // noEducation, noSkills, noLanguages.
      final codes = outcome.messages.map((m) => m.code).toSet();
      expect(codes, contains(ValidationCode.noExperience));
      expect(codes, contains(ValidationCode.noSkills));
      expect(codes, contains(ValidationCode.noLanguages));
    });

    test('ordre deterministe : identite avant experiences', () {
      final outcome =
          const CvValidationRules().evaluate(cvWith(info: const PersonalInfo()));
      final sections = outcome.messages.map((m) => m.section).toList();
      final idxIdentite = sections.indexOf('identite');
      final idxExp = sections.indexOf('experiences');
      expect(idxIdentite, lessThan(idxExp));
    });

    test('withRules : injecte un jeu de regles arbitraire', () {
      final outcome =
          const CvValidationRules.withRules([SkillsRule()]).evaluate(cvWith());
      expect(outcome.messages.single.code, ValidationCode.noSkills);
    });
  });
}
