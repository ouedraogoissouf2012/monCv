import 'package:cv_mobile/utils/cv_levels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('niveaux de compétence', () {
    test('les libellés restent cohérents de 1 à 5', () {
      expect(skillLevelLabel(1), 'Débutant');
      expect(skillLevelLabel(3), 'Avancé');
      expect(skillLevelLabel(5), 'Expert');
    });

    test('les progressions sont distinctes', () {
      expect(skillLevelProgress(1), 0.2);
      expect(skillLevelProgress(3), 0.6);
      expect(skillLevelProgress(5), 1.0);
    });
  });

  group('niveaux de langue', () {
    test('affiche le code CECRL avec son libellé', () {
      expect(languageLevelDisplay('B1'), 'B1 - Intermédiaire');
      expect(languageLevelDisplay('NATIF'), 'Natif');
    });

    test('B1 et natif ont des progressions différentes', () {
      expect(languageLevelProgress('B1'), 0.5);
      expect(languageLevelProgress('NATIF'), 1.0);
    });
  });
}
