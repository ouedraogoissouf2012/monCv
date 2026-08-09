import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/validators/cv_form_validator.dart';
import 'package:cv_mobile/services/cv_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identite valide exige prenom nom et email valide', () {
    expect(CvFormValidator.isPersonalInfoValid(null), false);
    expect(
      CvFormValidator.isPersonalInfoValid(
        const PersonalInfo(prenom: 'Awa', nom: 'Kone', email: 'invalide'),
      ),
      false,
    );
    expect(
      CvFormValidator.isPersonalInfoValid(
        const PersonalInfo(
          prenom: 'Awa',
          nom: 'Kone',
          email: 'awa@example.com',
        ),
      ),
      true,
    );
  });

  test('completion reflete les cinq sections', () {
    final cv = Cv(
      titre: 'CV',
      personalInfo: const PersonalInfo(
        prenom: 'Awa',
        nom: 'Kone',
        email: 'awa@example.com',
      ),
      experiences: [const Experience(poste: 'Dev')],
      educations: [const Education(diplome: 'Master')],
      skills: [const Skill(nom: 'Flutter')],
      projects: [const Project(nom: 'MonCV')],
    );

    expect(
      CvFormValidator.readinessScore(cv),
      const CvReadinessService().evaluate(cv).score,
    );
    expect(CvFormValidator.stepComplete(cv, 4), true);
  });

  test('categories backend sont mappees vers les bonnes etapes', () {
    expect(
      CvFormValidator.sectionForCategory('formations'),
      CvFormSection.education,
    );
    expect(
      CvFormValidator.sectionForCategory('langues'),
      CvFormSection.skills,
    );
    expect(
      CvFormValidator.sectionForCategory('projets'),
      CvFormSection.extras,
    );
    expect(
      CvFormValidator.sectionForCategory('inconnue'),
      CvFormSection.identity,
    );
  });
}
