import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/cv_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/l10n/app_localizations_fr.dart';

void main() {
  group('CvValidator.validateForSave', () {
    final validator = CvValidator();
    final l = AppLocalizationsFr();

    Cv baseCv({
      List<Experience> experiences = const [],
      List<Education> educations = const [],
      List<Skill> skills = const [],
      List<Language> languages = const [],
      List<Certification> certifications = const [],
      List<Project> projects = const [],
    }) {
      return Cv(
        titre: 'Developpeur Flutter',
        personalInfo: PersonalInfo(
          prenom: 'Issouf',
          nom: 'Ouedraogo',
          email: 'issouf@example.com',
        ),
        experiences: experiences,
        educations: educations,
        skills: skills,
        languages: languages,
        certifications: certifications,
        projects: projects,
      );
    }

    test('accepte un CV minimal sauvegardable par le backend', () {
      final issue = validator.validateForSave(baseCv(), l);

      expect(issue, isNull);
    });

    test('bloque une experience incomplete avant le POST API', () {
      final issue = validator.validateForSave(
        baseCv(
          experiences: [
            Experience(
              poste: 'Chef de projet',
              entreprise: '',
              dateDebut: DateTime(2024),
            ),
          ],
        ),
        l,
      );

      expect(issue?.category, 'experiences');
      expect(issue?.message.toLowerCase(), contains('entreprise obligatoire'));
    });

    test('bloque une formation sans date de debut', () {
      final issue = validator.validateForSave(
        baseCv(
          educations: [
            Education(
              etablissement: 'Universite',
              diplome: 'Licence',
            ),
          ],
        ),
        l,
      );

      expect(issue?.category, 'formations');
      expect(issue?.message.toLowerCase(), contains('debut obligatoire'));
    });

    test('bloque une langue sans niveau', () {
      final issue = validator.validateForSave(
        baseCv(languages: [Language(langue: 'Francais')]),
        l,
      );

      expect(issue?.category, 'langues');
      expect(issue?.message.toLowerCase(), contains('niveau obligatoire'));
    });

    test('bloque les extras incomplets', () {
      final certificationIssue = validator.validateForSave(
        baseCv(certifications: [Certification(nom: '')]),
        l,
      );
      final projectIssue = validator.validateForSave(
        baseCv(projects: [Project(nom: '')]),
        l,
      );

      expect(certificationIssue?.category, 'certifications');
      expect(certificationIssue?.message.toLowerCase(), contains('nom obligatoire'));
      expect(projectIssue?.category, 'projets');
      expect(projectIssue?.message.toLowerCase(), contains('nom obligatoire'));
    });
  });
}
