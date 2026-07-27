import 'package:cv_mobile/features/cv/domain/entities/certification.dart';
import 'package:cv_mobile/features/cv/domain/entities/education.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/features/cv/domain/entities/language.dart';
import 'package:cv_mobile/features/cv/domain/entities/project.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifie, pour chaque sous-entite, la semantique copyWith conserver /
/// remplacer / effacer (sentinel) et l'egalite structurelle.
void main() {
  group('Education', () {
    const base = Education(
      id: 1,
      etablissement: 'Univ',
      diplome: 'Master',
      domaine: 'Info',
      description: 'desc',
    );

    test('copyWith sans argument conserve tout', () {
      final c = base.copyWith();
      expect(c, base);
      expect(c.hashCode, base.hashCode);
    });

    test('copyWith remplace un champ', () {
      expect(base.copyWith(diplome: 'Licence').diplome, 'Licence');
      expect(base.copyWith(diplome: 'Licence').etablissement, 'Univ');
    });

    test('copyWith efface un nullable', () {
      final c = base.copyWith(diplome: null, description: null);
      expect(c.diplome, isNull);
      expect(c.description, isNull);
      expect(c.etablissement, 'Univ');
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(domaine: 'Autre'), isFalse);
    });
  });

  group('Experience', () {
    final base = Experience(
      id: 2,
      entreprise: 'Kalga',
      poste: 'Dev',
      lieu: 'Ouaga',
      dateDebut: DateTime(2020, 1, 1),
      description: 'desc',
      actuel: true,
    );

    test('copyWith conserve tout, y compris actuel', () {
      final c = base.copyWith();
      expect(c, base);
      expect(c.actuel, isTrue);
      expect(c.hashCode, base.hashCode);
    });

    test('copyWith bascule actuel et efface une date', () {
      final c = base.copyWith(actuel: false, dateDebut: null);
      expect(c.actuel, isFalse);
      expect(c.dateDebut, isNull);
      expect(c.entreprise, 'Kalga');
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(poste: 'Lead'), isFalse);
    });
  });

  group('Skill', () {
    const base = Skill(id: 3, nom: 'Flutter', niveau: 5, categorie: 'Mobile');

    test('copyWith conserve/efface', () {
      expect(base.copyWith(), base);
      expect(base.copyWith(niveau: null).niveau, isNull);
      expect(base.copyWith(nom: 'Dart').nom, 'Dart');
      expect(base.hashCode, base.copyWith().hashCode);
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(categorie: 'Backend'), isFalse);
    });
  });

  group('Language', () {
    const base = Language(id: 4, langue: 'FR', niveau: 'NATIF');

    test('copyWith conserve/remplace/efface', () {
      expect(base.copyWith(), base);
      expect(base.copyWith(niveau: 'C1').niveau, 'C1');
      expect(base.copyWith(niveau: null).niveau, isNull);
      expect(base.hashCode, base.copyWith().hashCode);
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(langue: 'EN'), isFalse);
    });
  });

  group('Certification', () {
    final base = Certification(
      id: 5,
      nom: 'AWS',
      organisme: 'Amazon',
      dateObtention: DateTime(2021, 3, 10),
      dateExpiration: DateTime(2024, 3, 10),
      credentialUrl: 'https://x',
    );

    test('copyWith conserve/efface les dates', () {
      expect(base.copyWith(), base);
      final c = base.copyWith(dateExpiration: null, credentialUrl: null);
      expect(c.dateExpiration, isNull);
      expect(c.credentialUrl, isNull);
      expect(c.dateObtention, DateTime(2021, 3, 10));
      expect(base.hashCode, base.copyWith().hashCode);
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(organisme: 'Autre'), isFalse);
    });
  });

  group('Project', () {
    final base = Project(
      id: 6,
      nom: 'MonCV',
      description: 'desc',
      technologies: 'Flutter',
      lien: 'https://x',
      dateDebut: DateTime(2020, 1, 1),
      dateFin: DateTime(2020, 12, 31),
    );

    test('copyWith conserve/remplace/efface', () {
      expect(base.copyWith(), base);
      expect(base.copyWith(nom: 'Autre').nom, 'Autre');
      final c = base.copyWith(lien: null, dateFin: null);
      expect(c.lien, isNull);
      expect(c.dateFin, isNull);
      expect(c.technologies, 'Flutter');
      expect(base.hashCode, base.copyWith().hashCode);
    });

    test('egalite : une difference casse', () {
      expect(base == base.copyWith(technologies: 'Dart'), isFalse);
    });
  });
}
