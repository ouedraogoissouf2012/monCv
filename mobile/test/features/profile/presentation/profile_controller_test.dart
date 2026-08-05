import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/profile/presentation/profile_controller.dart';

void main() {
  group('ProfileController.initialsOf (#250 E3)', () {
    test('nom complet -> deux initiales majuscules', () {
      expect(ProfileController.initialsOf('Jean Dupont'), 'JD');
    });

    test('prenom seul -> une initiale', () {
      expect(ProfileController.initialsOf('Jean'), 'J');
    });

    test('espaces multiples entre prenom et nom (ne plante pas)', () {
      // Regression : le monolithe faisait split(' ') -> parts[1] == '' -> crash.
      expect(ProfileController.initialsOf('Jean   Dupont'), 'JD');
    });

    test('espaces superflus en tete/pied', () {
      expect(ProfileController.initialsOf('  Alice Martin  '), 'AM');
    });

    test('null -> point d interrogation', () {
      expect(ProfileController.initialsOf(null), '?');
    });

    test('chaine vide ou espaces seuls -> point d interrogation', () {
      expect(ProfileController.initialsOf(''), '?');
      expect(ProfileController.initialsOf('   '), '?');
    });

    test('trois mots -> initiales des deux premiers', () {
      expect(ProfileController.initialsOf('Jean Pierre Dupont'), 'JP');
    });
  });

  group('ProfileController.from (#250 E3)', () {
    test('cable le dashboard et l entete', () {
      final controller = ProfileController.from(
        fullName: 'Jean Dupont',
        email: 'jean@exemple.fr',
        cvCount: 5,
      );

      expect(controller.fullName, 'Jean Dupont');
      expect(controller.email, 'jean@exemple.fr');
      expect(controller.initials, 'JD');
      expect(controller.dashboard.cvCount, 5);
    });

    test('email null -> chaine vide (repli d affichage a la vue)', () {
      final controller = ProfileController.from(cvCount: 0);

      expect(controller.email, '');
      expect(controller.fullName, isNull);
      expect(controller.initials, '?');
    });
  });
}
