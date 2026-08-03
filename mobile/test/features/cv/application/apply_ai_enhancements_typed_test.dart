import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/cv/application/apply_ai_enhancements.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apply = ApplyAiEnhancements();

  Cv sampleCv() => Cv(
        id: 1,
        titre: 'CV',
        personalInfo: const PersonalInfo(
          nom: 'Ouedraogo',
          prenom: 'Issouf',
          titrePoste: 'Dev',
          resumeProfessionnel: 'ancien resume',
        ),
        experiences: [
          const Experience(
              id: 10, poste: 'Dev', entreprise: 'ACME', description: 'ancienne'),
        ],
        skills: [const Skill(id: 20, nom: 'Java', niveau: 4)],
      );

  group('ApplyAiEnhancements.fromEnhanced (#244 F4a)', () {
    test('remplace uniquement les champs fournis non vides', () {
      const enhanced = EnhancedCv(
        titrePoste: 'Developpeur Senior', // modifie
        resumeProfessionnel: '', // vide -> ignore
        experiences: [EnhancedExperience(id: 10, description: 'amelioree')],
      );

      final out = apply.fromEnhanced(sampleCv(), enhanced);
      expect(out.personalInfo?.titrePoste, 'Developpeur Senior');
      expect(out.personalInfo?.resumeProfessionnel, 'ancien resume',
          reason: 'valeur vide ne detruit pas l existant');
      expect(out.experiences.first.description, 'amelioree');
      // Champs non touches conserves.
      expect(out.experiences.first.entreprise, 'ACME');
    });

    test('IDs preserves sur toutes les sections modifiees', () {
      const enhanced = EnhancedCv(
        experiences: [EnhancedExperience(id: 10, poste: 'Lead')],
        skills: [EnhancedSkill(nom: 'Java 21', niveau: 5)],
      );
      final out = apply.fromEnhanced(sampleCv(), enhanced);
      expect(out.experiences.first.id, 10);
      expect(out.skills.first.id, 20);
    });

    test('niveau de competence conserve si l IA n en fournit pas', () {
      const enhanced = EnhancedCv(skills: [EnhancedSkill(nom: 'Java 21')]);
      final out = apply.fromEnhanced(sampleCv(), enhanced);
      expect(out.skills.first.nom, 'Java 21');
      expect(out.skills.first.niveau, 4, reason: 'niveau original conserve');
    });

    test('liste amelioree plus courte -> extras du CV inchanges', () {
      final cv = sampleCv().copyWith(experiences: [
        const Experience(id: 10, poste: 'A', description: 'da'),
        const Experience(id: 11, poste: 'B', description: 'db'),
      ]);
      const enhanced =
          EnhancedCv(experiences: [EnhancedExperience(id: 10, poste: 'A+')]);
      final out = apply.fromEnhanced(cv, enhanced);
      expect(out.experiences[0].poste, 'A+');
      expect(out.experiences[1].poste, 'B', reason: 'non touche');
      expect(out.experiences, hasLength(2));
    });

    test('personalInfo null reste null', () {
      final cv = Cv(id: 1, titre: 'CV');
      const enhanced = EnhancedCv(titrePoste: 'X');
      expect(apply.fromEnhanced(cv, enhanced).personalInfo, isNull);
    });

    test('accents preserves', () {
      const enhanced = EnhancedCv(titrePoste: 'Ingénieur réseau');
      final out = apply.fromEnhanced(sampleCv(), enhanced);
      expect(out.personalInfo?.titrePoste, 'Ingénieur réseau');
    });
  });

  group('Equivalence voie typee vs voie Map (#244 F4a)', () {
    test('fromEnhanced produit le meme CV que call(Map) equivalent', () {
      final cv = sampleCv();
      const enhanced = EnhancedCv(
        titrePoste: 'Developpeur Senior',
        experiences: [EnhancedExperience(id: 10, description: 'amelioree')],
        skills: [EnhancedSkill(nom: 'Java 21', niveau: 5)],
      );
      final viaTyped = apply.fromEnhanced(cv, enhanced);
      final viaMap = apply(cv, {
        'titrePoste': 'Developpeur Senior',
        'experiences': [
          {'description': 'amelioree'}
        ],
        'skills': [
          {'nom': 'Java 21', 'niveau': 5}
        ],
      });

      expect(viaTyped.personalInfo?.titrePoste, viaMap.personalInfo?.titrePoste);
      expect(viaTyped.experiences.first.description,
          viaMap.experiences.first.description);
      expect(viaTyped.skills.first.nom, viaMap.skills.first.nom);
      expect(viaTyped.skills.first.niveau, viaMap.skills.first.niveau);
      expect(viaTyped.experiences.first.id, viaMap.experiences.first.id);
    });
  });
}
