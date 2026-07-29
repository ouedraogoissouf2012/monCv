import 'package:cv_mobile/features/cv/application/apply_ai_enhancements.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apply = ApplyAiEnhancements();

  Cv baseCv() => Cv(
        titre: 'Dev',
        personalInfo: const PersonalInfo(
          prenom: 'Issouf',
          nom: 'Ouedraogo',
          email: 'a@b.co',
          titrePoste: 'Ancien titre',
          resumeProfessionnel: 'Ancien resume',
        ),
        experiences: [
          const Experience(id: 1, poste: 'Dev', entreprise: 'ACME'),
        ],
        skills: [const Skill(id: 5, nom: 'Java', niveau: 4)],
      );

  group('ApplyAiEnhancements - merge partiel (#240)', () {
    test('applique titre et resume quand fournis', () {
      final result = apply(baseCv(), {
        'titrePoste': 'Nouveau titre',
        'resumeProfessionnel': 'Nouveau resume',
      });
      expect(result.personalInfo?.titrePoste, 'Nouveau titre');
      expect(result.personalInfo?.resumeProfessionnel, 'Nouveau resume');
    });

    test('conserve la valeur existante quand l IA renvoie vide', () {
      final result = apply(baseCv(), {
        'titrePoste': '',
        'resumeProfessionnel': null,
      });
      expect(result.personalInfo?.titrePoste, 'Ancien titre');
      expect(result.personalInfo?.resumeProfessionnel, 'Ancien resume');
    });

    test('un map vide ne modifie rien', () {
      final cv = baseCv();
      final result = apply(cv, {});
      expect(result.personalInfo?.titrePoste, cv.personalInfo?.titrePoste);
      expect(result.experiences.first.poste, 'Dev');
      expect(result.skills.first.nom, 'Java');
    });
  });

  group('ApplyAiEnhancements - identifiants et champs preserves', () {
    test('l id d une experience est conserve apres merge', () {
      final result = apply(baseCv(), {
        'experiences': [
          {'poste': 'Lead Dev', 'description': 'Nouvelle desc'},
        ],
      });
      expect(result.experiences.first.id, 1);
      expect(result.experiences.first.poste, 'Lead Dev');
      expect(result.experiences.first.entreprise, 'ACME'); // champ non touche
    });

    test('un champ vide dans une experience preserve l ancien', () {
      final result = apply(baseCv(), {
        'experiences': [
          {'poste': '', 'description': 'Desc seule'},
        ],
      });
      expect(result.experiences.first.poste, 'Dev'); // conserve
      expect(result.experiences.first.description, 'Desc seule');
    });
  });

  group('ApplyAiEnhancements - listes de tailles differentes', () {
    test('plus d experiences IA que dans le CV : les extras sont ignores', () {
      final result = apply(baseCv(), {
        'experiences': [
          {'poste': 'A'},
          {'poste': 'B'}, // pas d experience correspondante
        ],
      });
      expect(result.experiences.length, 1);
      expect(result.experiences.first.poste, 'A');
    });

    test('les skills IA remplacent la liste par index avec fallback', () {
      final result = apply(baseCv(), {
        'skills': [
          {'nom': 'Dart', 'niveau': 5},
          {'nom': 'Flutter'}, // niveau absent -> defaut
        ],
      });
      expect(result.skills.length, 2);
      expect(result.skills[0].id, 5); // ancien id conserve pour index 0
      expect(result.skills[0].nom, 'Dart');
      expect(result.skills[1].niveau, 3); // defaut
    });

    test('valeur non-liste pour une section : section inchangee', () {
      final result = apply(baseCv(), {'experiences': 'pas une liste'});
      expect(result.experiences.length, 1);
      expect(result.experiences.first.poste, 'Dev');
    });
  });
}
