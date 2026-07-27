import 'package:cv_mobile/features/cv/data/mappers/cv_section_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CvSectionMapper();

  group('PersonalInfo', () {
    test('map complet aller/retour', () {
      const json = {
        'nom': 'Doe',
        'prenom': 'John',
        'email': 'j@e.com',
        'telephone': '0600',
        'adresse': '1 rue',
        'ville': 'Paris',
        'codePostal': '75000',
        'pays': 'France',
        'photoUrl': '/media/p.png',
        'linkedIn': 'in/john',
        'portfolio': 'john.dev',
        'titrePoste': 'Dev',
        'resumeProfessionnel': 'Expert.',
      };
      final info = mapper.personalInfoFromJson(json);
      expect(info.nom, 'Doe');
      expect(info.resumeProfessionnel, 'Expert.');
      expect(mapper.personalInfoToJson(info), json);
    });

    test('champs absents => null', () {
      final info = mapper.personalInfoFromJson(const {'nom': 'Doe'});
      expect(info.nom, 'Doe');
      expect(info.email, isNull);
      expect(info.ville, isNull);
    });
  });

  group('Experience — dates et booleen', () {
    test('parse dates ISO date-only et actuel', () {
      final exp = mapper.experienceFromJson(const {
        'id': 1,
        'poste': 'Dev',
        'dateDebut': '2020-01-15',
        'dateFin': '2022-06-30',
        'actuel': true,
      });
      expect(exp.dateDebut, DateTime(2020, 1, 15));
      expect(exp.dateFin, DateTime(2022, 6, 30));
      expect(exp.actuel, isTrue);
    });

    test('date invalide => null (pas de throw)', () {
      final exp = mapper.experienceFromJson(const {
        'poste': 'Dev',
        'dateDebut': 'not-a-date',
        'dateFin': '',
      });
      expect(exp.dateDebut, isNull);
      expect(exp.dateFin, isNull);
    });

    test('actuel absent => false', () {
      final exp = mapper.experienceFromJson(const {'poste': 'Dev'});
      expect(exp.actuel, isFalse);
    });

    test('emission date-only (sans composante horaire)', () {
      final json = mapper.experienceToJson(
        mapper.experienceFromJson(const {'dateDebut': '2020-01-15'}),
      );
      expect(json['dateDebut'], '2020-01-15');
    });
  });

  group('Skill — niveau non entier', () {
    test('niveau int conserve', () {
      final s = mapper.skillFromJson(const {'nom': 'Flutter', 'niveau': 4});
      expect(s.niveau, 4);
    });

    test('niveau absent => null', () {
      final s = mapper.skillFromJson(const {'nom': 'Flutter'});
      expect(s.niveau, isNull);
    });
  });

  group('Listes de sections', () {
    test('liste absente => liste vide', () {
      expect(mapper.experiencesFromJson(null), isEmpty);
    });

    test('liste presente => elements mappes', () {
      final list = mapper.experiencesFromJson(const [
        {'poste': 'Dev'},
        {'poste': 'Lead'},
      ]);
      expect(list, hasLength(2));
      expect(list[1].poste, 'Lead');
    });
  });

  group('Certification / Project / Education / Language', () {
    test('education aller/retour avec dates', () {
      final edu = mapper.educationFromJson(const {
        'etablissement': 'Univ',
        'dateDebut': '2018-09-01',
      });
      expect(edu.etablissement, 'Univ');
      expect(mapper.educationToJson(edu)['dateDebut'], '2018-09-01');
    });

    test('certification dates', () {
      final cert = mapper.certificationFromJson(const {
        'nom': 'AWS',
        'dateObtention': '2021-03-10',
      });
      expect(cert.dateObtention, DateTime(2021, 3, 10));
    });

    test('project technologies', () {
      final p = mapper.projectFromJson(const {
        'nom': 'MonCV',
        'technologies': 'Flutter, Dart',
      });
      expect(p.technologies, 'Flutter, Dart');
    });

    test('language niveau string', () {
      final l = mapper.languageFromJson(const {'langue': 'FR', 'niveau': 'NATIF'});
      expect(l.niveau, 'NATIF');
    });
  });
}
