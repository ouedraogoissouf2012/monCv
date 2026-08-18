import 'dart:typed_data';

import 'package:cv_mobile/features/cv/presentation/personal_info/personal_info_form_controller.dart';
import 'package:cv_mobile/features/cv/domain/entities/personal_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonalInfoFormController (#242 D2)', () {
    test('fromPersonalInfo initialise chaque controller', () {
      const info = PersonalInfo(
        nom: 'Traore',
        prenom: 'Alex',
        email: 'a@b.co',
        telephone: '+226 70 00 00 00',
        adresse: '10 rue X',
        ville: 'Ouagadougou',
        codePostal: '01',
        pays: 'Burkina Faso',
        titrePoste: 'Dev Flutter',
        linkedIn: 'in/alextraore',
        portfolio: 'https://x.dev',
        resumeProfessionnel: 'Resume',
        photoUrl: 'https://cdn/x.png',
      );

      final c = PersonalInfoFormController.fromPersonalInfo(info);
      addTearDown(c.dispose);

      expect(c.nom.text, 'Traore');
      expect(c.prenom.text, 'Alex');
      expect(c.email.text, 'a@b.co');
      expect(c.telephone.text, '+226 70 00 00 00');
      expect(c.pays.text, 'Burkina Faso');
      expect(c.titrePoste.text, 'Dev Flutter');
      expect(c.resume.text, 'Resume');
      expect(c.photoUrl, 'https://cdn/x.png');
    });

    test('fromPersonalInfo(null) -> tous les champs vides', () {
      final c = PersonalInfoFormController.fromPersonalInfo(null);
      addTearDown(c.dispose);

      expect(c.nom.text, isEmpty);
      expect(c.email.text, isEmpty);
      expect(c.pays.text, isEmpty);
      expect(c.photoUrl, isNull);
      expect(c.photoBytes, isNull);
    });

    test('toPersonalInfo : champ vide -> null (comportement historique)', () {
      final c = PersonalInfoFormController.fromPersonalInfo(null);
      addTearDown(c.dispose);
      c.nom.text = 'Dupont';
      // email reste vide

      final info = c.toPersonalInfo();
      expect(info.nom, 'Dupont');
      expect(info.email, isNull);
      expect(info.telephone, isNull);
      expect(info.pays, isNull);
    });

    test('round-trip fromPersonalInfo -> toPersonalInfo est fidele', () {
      const original = PersonalInfo(
        nom: 'N',
        prenom: 'P',
        email: 'e@x.co',
        pays: 'France',
        photoUrl: 'https://p/x.png',
      );

      final c = PersonalInfoFormController.fromPersonalInfo(original);
      addTearDown(c.dispose);
      final round = c.toPersonalInfo();

      expect(round.nom, original.nom);
      expect(round.prenom, original.prenom);
      expect(round.email, original.email);
      expect(round.pays, original.pays);
      expect(round.photoUrl, original.photoUrl);
      // Les champs absents restent absents (null), pas de chaine vide.
      expect(round.ville, isNull);
      expect(round.linkedIn, isNull);
    });

    test('clearPhoto remet url et bytes a null', () {
      final c = PersonalInfoFormController.fromPersonalInfo(
        const PersonalInfo(photoUrl: 'https://p/x.png'),
      );
      addTearDown(c.dispose);
      c.photoBytes = Uint8List.fromList([1, 2, 3]);

      c.clearPhoto();

      expect(c.photoUrl, isNull);
      expect(c.photoBytes, isNull);
      expect(c.toPersonalInfo().photoUrl, isNull);
    });

    test('photoBytes n influence pas la serialisation PersonalInfo', () {
      final c = PersonalInfoFormController.fromPersonalInfo(null);
      addTearDown(c.dispose);
      c.photoBytes = Uint8List.fromList([9, 9, 9]);

      // Les bytes locaux ne sont pas serialises (seul photoUrl l'est).
      expect(c.toPersonalInfo().photoUrl, isNull);
    });
  });
}
