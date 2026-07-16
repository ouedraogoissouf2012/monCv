import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:cv_mobile/services/cv_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CvReadinessService();

  Cv readyCv() => Cv(
        titre: 'Développeur Flutter mobile',
        style: const CvStyle(templateId: 'ats'),
        personalInfo: PersonalInfo(
          prenom: 'Awa',
          nom: 'Kone',
          email: 'awa@example.com',
          telephone: '+225 01 02 03 04 05',
          titrePoste: 'Développeuse Flutter',
          resumeProfessionnel:
              'Développeuse Flutter avec trois années de pratique sur des applications mobiles. '
              'Réalisation de parcours clients, intégration API et tests automatisés pour fiabiliser les livraisons.',
        ),
        experiences: [
          Experience(
            poste: 'Développeuse mobile',
            entreprise: 'Acme',
            dateDebut: DateTime(2022, 1),
            actuel: true,
            description:
                'Développement de parcours Flutter, intégration de services REST et ajout de tests automatisés. '
                'Réduction des anomalies observées avant les mises en production.',
          ),
        ],
        educations: [
          Education(
            etablissement: 'Université',
            diplome: 'Licence informatique',
            dateDebut: DateTime(2018, 9),
            dateFin: DateTime(2021, 6),
          ),
        ],
        skills: [Skill(nom: 'Flutter'), Skill(nom: 'Dart')],
      );

  test('un CV factuel et ATS obtient un score de preparation eleve', () {
    final report = service.evaluate(readyCv());

    expect(report.score, greaterThanOrEqualTo(80));
    expect(report.isReady, isTrue);
    expect(report.issues, isEmpty);
  });

  test('detecte le titre vague, le texte generique et les dates suspectes', () {
    final report = service.evaluate(Cv(
      titre: 'Concours',
      personalInfo: PersonalInfo(
        titrePoste: 'Concours',
        resumeProfessionnel:
            "Candidat motivé, sérieux, rigoureux et passionné souhaitant intégrer l'armé.",
      ),
      experiences: [Experience(poste: 'Vendeur', entreprise: 'SK')],
      educations: [
        Education(
          etablissement: 'Académie',
          diplome: 'BAC',
          dateDebut: DateTime(2024, 7, 1),
          dateFin: DateTime(2024, 7, 4),
        ),
      ],
      skills: [Skill(nom: 'Motivation')],
    ));

    expect(report.score, lessThan(50));
    expect(report.isReady, isFalse);
    expect(
      report.issues.map((issue) => issue.code),
      containsAll([
        'specific_title',
        'email',
        'phone',
        'generic_profile',
        'proofreading',
        'experience_details',
        'education_dates',
        'ats_template',
      ]),
    );
  });

  test('evaluation reste identique apres serialisation et rechargement', () {
    final original = readyCv();
    final reloaded = Cv.fromJson({
      ...original.toJson(),
      'id': 42,
      'createdAt': '2026-07-16T10:00:00',
      'updatedAt': '2026-07-16T10:01:00',
    });

    final reloadedJson = reloaded.toJson()..remove('id');
    expect(reloadedJson, original.toJson());
    expect(service.evaluate(reloaded).score, service.evaluate(original).score);
    expect(service.evaluate(reloaded).isReady, isTrue);
  });
}
