import 'package:cv_mobile/features/cv/domain/entities/personal_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonalInfo.fullName', () {
    test('prenom + nom presents', () {
      const info = PersonalInfo(prenom: 'John', nom: 'Doe');
      expect(info.fullName, 'John Doe');
    });

    test('prenom seul', () {
      const info = PersonalInfo(prenom: 'John');
      expect(info.fullName, 'John');
    });

    test('nom seul', () {
      const info = PersonalInfo(nom: 'Doe');
      expect(info.fullName, 'Doe');
    });

    test('aucun des deux', () {
      const info = PersonalInfo();
      expect(info.fullName, '');
    });
  });

  group('PersonalInfo.copyWith', () {
    const base = PersonalInfo(
      nom: 'Doe',
      prenom: 'John',
      email: 'j@e.com',
      telephone: '0600',
    );

    test('sans argument, conserve tous les champs', () {
      final copy = base.copyWith();
      expect(copy.nom, 'Doe');
      expect(copy.prenom, 'John');
      expect(copy.email, 'j@e.com');
      expect(copy.telephone, '0600');
    });

    test('remplace un champ passe', () {
      final copy = base.copyWith(email: 'new@e.com');
      expect(copy.email, 'new@e.com');
      expect(copy.nom, 'Doe'); // les autres conserves
    });

    test('efface explicitement un nullable avec null', () {
      final copy = base.copyWith(email: null);
      expect(copy.email, isNull);
      // les autres champs restent intacts (pas d'effacement collateral)
      expect(copy.nom, 'Doe');
      expect(copy.telephone, '0600');
    });

    test('distingue effacer de conserver sur des champs distincts', () {
      final copy = base.copyWith(email: null, telephone: '0700');
      expect(copy.email, isNull);
      expect(copy.telephone, '0700');
      expect(copy.nom, 'Doe');
    });
  });

  group('PersonalInfo egalite', () {
    test('structurelle', () {
      expect(
        const PersonalInfo(nom: 'Doe', email: 'a@b.c'),
        const PersonalInfo(nom: 'Doe', email: 'a@b.c'),
      );
    });

    test('un champ different casse l egalite', () {
      expect(
        const PersonalInfo(nom: 'Doe') == const PersonalInfo(nom: 'Roe'),
        isFalse,
      );
    });

    test('hashCode coherent avec == sur un objet a tous les champs', () {
      const full = PersonalInfo(
        nom: 'Doe',
        prenom: 'John',
        email: 'j@e.com',
        telephone: '0600',
        adresse: '1 rue',
        ville: 'Paris',
        codePostal: '75000',
        pays: 'France',
        photoUrl: 'p.png',
        linkedIn: 'in/j',
        portfolio: 'j.dev',
        titrePoste: 'Dev',
        resumeProfessionnel: 'Expert.',
      );
      final copy = full.copyWith();
      expect(copy, full);
      expect(copy.hashCode, full.hashCode);
    });
  });
}
