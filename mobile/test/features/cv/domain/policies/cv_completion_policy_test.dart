import 'package:cv_mobile/features/cv/domain/entities/certification.dart';
import 'package:cv_mobile/features/cv/domain/entities/cv.dart';
import 'package:cv_mobile/features/cv/domain/entities/education.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/features/cv/domain/entities/language.dart';
import 'package:cv_mobile/features/cv/domain/entities/personal_info.dart';
import 'package:cv_mobile/features/cv/domain/entities/project.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:cv_mobile/features/cv/domain/policies/cv_completion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = CvCompletionPolicy();

  group('CvCompletionPolicy — non-regression du bareme historique', () {
    // Reprend les assertions de test/widgets/cv_card_test.dart:176-213.
    test('titre seul = 10 pts', () {
      expect(policy.score(CvEntity(titre: 'Test')), 10);
    });

    test('titre + nom + prenom + email = 30 pts', () {
      final cv = CvEntity(
        titre: 'Test',
        personalInfo: const PersonalInfo(
          nom: 'Doe',
          prenom: 'John',
          email: 'j@e.com',
        ),
      );
      expect(policy.score(cv), 30);
    });

    test('CV complet = 100 pts', () {
      final cv = CvEntity(
        titre: 'CV',
        personalInfo: const PersonalInfo(
          nom: 'Doe',
          prenom: 'John',
          email: 'j@e.com',
          telephone: '0600',
          titrePoste: 'Dev',
          adresse: '1 rue',
          resumeProfessionnel: 'Expert.',
        ),
        experiences: [const Experience(poste: 'Dev')],
        educations: [const Education(etablissement: 'Univ')],
        skills: [const Skill(nom: 'Flutter')],
        languages: [const Language(langue: 'FR', niveau: 'NATIF')],
        certifications: [const Certification(nom: 'AWS')],
        projects: [const Project(nom: 'MonCV')],
      );
      expect(policy.score(cv), 100);
    });
  });

  group('CvCompletionPolicy — contribution isolee de chaque critere', () {
    // Table : (libelle, CV, points attendus, titre de base=10 inclus).
    final cases = <({String label, CvEntity cv, int expected})>[
      (label: 'identite (nom+prenom)', expected: 20,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(nom: 'D', prenom: 'J'))),
      (label: 'email', expected: 20,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(email: 'a@b.c'))),
      (label: 'telephone', expected: 15,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(telephone: '06'))),
      (label: 'titrePoste', expected: 15,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(titrePoste: 'Dev'))),
      (label: 'adresse', expected: 15,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(adresse: '1 rue'))),
      (label: 'ville (equivalent adresse)', expected: 15,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(ville: 'Paris'))),
      (label: 'resume', expected: 20,
       cv: CvEntity(titre: 'T',
           personalInfo: const PersonalInfo(resumeProfessionnel: 'x'))),
      (label: 'experiences', expected: 25,
       cv: CvEntity(titre: 'T', experiences: [const Experience()])),
      (label: 'educations', expected: 20,
       cv: CvEntity(titre: 'T', educations: [const Education()])),
      (label: 'skills', expected: 15,
       cv: CvEntity(titre: 'T', skills: [const Skill()])),
      (label: 'languages', expected: 15,
       cv: CvEntity(titre: 'T', languages: [const Language()])),
      (label: 'certifications', expected: 15,
       cv: CvEntity(titre: 'T', certifications: [const Certification()])),
      (label: 'projects', expected: 15,
       cv: CvEntity(titre: 'T', projects: [const Project()])),
    ];

    for (final c in cases) {
      test('${c.label} => ${c.expected} pts', () {
        expect(policy.score(c.cv), c.expected);
      });
    }
  });

  group('CvCompletionPolicy — cas limites', () {
    test('titre vide (espaces) ne compte pas', () {
      expect(policy.score(CvEntity(titre: '   ')), 0);
    });

    test('identite partielle (nom sans prenom) ne compte pas', () {
      final cv = CvEntity(titre: 'T',
          personalInfo: const PersonalInfo(nom: 'Doe'));
      expect(policy.score(cv), 10); // titre uniquement
    });

    test('email vide ne compte pas', () {
      final cv = CvEntity(titre: 'T',
          personalInfo: const PersonalInfo(email: ''));
      expect(policy.score(cv), 10);
    });

    test('maxScore vaut 100 avec les poids par defaut', () {
      expect(policy.maxScore, 100);
    });
  });

  group('CvCompletionPolicy — poids configurables', () {
    test('des poids custom modifient le score', () {
      const custom = CvCompletionPolicy(
        weights: (
          titre: 50, identite: 0, email: 0, telephone: 0, titrePoste: 0,
          adresseOuVille: 0, resume: 0, experiences: 50, educations: 0,
          skills: 0, languages: 0, certifications: 0, projects: 0,
        ),
      );
      final cv = CvEntity(titre: 'T', experiences: [const Experience()]);
      expect(custom.score(cv), 100);
      expect(custom.maxScore, 100);
    });
  });
}
