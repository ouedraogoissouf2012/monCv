import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/ai_enhancement/application/build_enhancement_diff.dart';
import 'package:cv_mobile/features/ai_enhancement/domain/enhancement_change.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const diff = BuildEnhancementDiff();

  List<EnhancementChange> forField(
          List<EnhancementChange> changes, EnhancementField f) =>
      changes.where((c) => c.field == f).toList();

  group('BuildEnhancementDiff - champs uniques (#244 F1)', () {
    test('titre modifie -> un change; resume inchange -> aucun', () {
      final cv = Cv(
        titre: 'x',
        personalInfo: const PersonalInfo(
            titrePoste: 'Dev', resumeProfessionnel: 'Resume stable'),
      );
      const enhanced = EnhancedCv(
        titrePoste: 'Developpeur Senior',
        resumeProfessionnel: 'Resume stable', // identique -> ignore
      );

      final changes = diff(cv, enhanced);
      final title = forField(changes, EnhancementField.jobTitle);
      expect(title, hasLength(1));
      expect(title.single.before, 'Dev');
      expect(title.single.after, 'Developpeur Senior');
      expect(forField(changes, EnhancementField.professionalSummary), isEmpty);
    });

    test('valeur amelioree vide -> aucun change (ne detruit pas l existant)',
        () {
      final cv = Cv(
          titre: 'x',
          personalInfo: const PersonalInfo(titrePoste: 'Dev'));
      const enhanced = EnhancedCv(titrePoste: ''); // vide -> ignore
      expect(forField(diff(cv, enhanced), EnhancementField.jobTitle), isEmpty);
    });
  });

  group('BuildEnhancementDiff - sections en liste (#244 F1)', () {
    test('experiences comparees par index (poste + description)', () {
      final cv = Cv(titre: 'x', experiences: [
        const Experience(poste: 'Dev', description: 'ancienne desc'),
        const Experience(poste: 'Lead', description: 'desc lead'),
      ]);
      const enhanced = EnhancedCv(experiences: [
        EnhancedExperience(poste: 'Dev', description: 'nouvelle desc'),
        EnhancedExperience(poste: 'Tech Lead', description: 'desc lead'),
      ]);

      final changes = diff(cv, enhanced);
      // exp[0] : poste inchange (ignore), description modifiee.
      final desc0 = changes.where((c) =>
          c.field == EnhancementField.experienceDescription && c.index == 0);
      expect(desc0.single.after, 'nouvelle desc');
      expect(forField(changes, EnhancementField.experiencePoste)
          .where((c) => c.index == 0), isEmpty);
      // exp[1] : poste modifie, description inchangee.
      final poste1 = changes.where((c) =>
          c.field == EnhancementField.experiencePoste && c.index == 1);
      expect(poste1.single.after, 'Tech Lead');
    });

    test('liste amelioree plus courte -> pas d acces hors bornes', () {
      final cv = Cv(titre: 'x', experiences: [
        const Experience(poste: 'A', description: 'da'),
        const Experience(poste: 'B', description: 'db'),
        const Experience(poste: 'C', description: 'dc'),
      ]);
      const enhanced = EnhancedCv(experiences: [
        EnhancedExperience(poste: 'A+', description: 'da'),
      ]);

      final changes = diff(cv, enhanced);
      // Seul l'index 0 est compare ; aucun change pour 1 et 2.
      final postes = forField(changes, EnhancementField.experiencePoste);
      expect(postes, hasLength(1));
      expect(postes.single.index, 0);
      expect(postes.single.after, 'A+');
    });

    test('liste amelioree plus longue -> extras ignores (borne au CV)', () {
      final cv = Cv(titre: 'x', skills: [const Skill(nom: 'Java')]);
      const enhanced = EnhancedCv(skills: [
        EnhancedSkill(nom: 'Java 21'),
        EnhancedSkill(nom: 'Kotlin'), // extra, pas d'original -> ignore
      ]);

      final changes = forField(diff(cv, enhanced), EnhancementField.skill);
      expect(changes, hasLength(1));
      expect(changes.single.index, 0);
      expect(changes.single.after, 'Java 21');
    });
  });

  group('BuildEnhancementDiff - robustesse (#244 F1)', () {
    test('accents preserves dans before/after', () {
      final cv = Cv(
          titre: 'x',
          personalInfo:
              const PersonalInfo(titrePoste: 'Developpeur reseau'));
      const enhanced = EnhancedCv(titrePoste: 'Ingénieur réseau sécurisé');

      final change =
          forField(diff(cv, enhanced), EnhancementField.jobTitle).single;
      expect(change.after, 'Ingénieur réseau sécurisé');
    });

    test('CV et resultat vides -> aucun change', () {
      final changes = diff(Cv(titre: 'x'), const EnhancedCv());
      expect(changes, isEmpty);
    });

    test('seuls des accents deja connus -> aucun change', () {
      final cv = Cv(titre: 'x', experiences: [
        const Experience(poste: 'Developpeur Web Full Stack'),
      ], educations: [
        const Education(
            etablissement: 'Universite Aube Nouvelle de Bobo-Dioulasso'),
      ]);
      const enhanced = EnhancedCv(experiences: [
        EnhancedExperience(poste: 'Développeur Web Full Stack'),
      ], educations: [
        EnhancedEducation(
            etablissement: 'Université Aube Nouvelle de Bobo-Dioulasso'),
      ]);

      expect(diff(cv, enhanced), isEmpty);
    });

    test('relecture : champ invente (avant vide) ignore', () {
      const proofread = BuildEnhancementDiff(proofread: true);
      final cv = Cv(titre: 'x', educations: [
        const Education(etablissement: 'ESI', description: ''),
      ]);
      const enhanced = EnhancedCv(educations: [
        EnhancedEducation(
            etablissement: 'ESI', description: 'Parcours invente'),
      ]);

      expect(proofread(cv, enhanced), isEmpty);
    });

    test('toutes les sections couvertes (formation/certif/projet/langue)', () {
      final cv = Cv(titre: 'x', educations: [
        const Education(diplome: 'Licence', etablissement: 'ESI'),
      ], certifications: [
        const Certification(nom: 'AWS'),
      ], projects: [
        const Project(nom: 'App', technologies: 'Dart'),
      ], languages: [
        const Language(langue: 'Anglais'),
      ]);
      const enhanced = EnhancedCv(educations: [
        EnhancedEducation(diplome: 'Master', etablissement: 'ESI'),
      ], certifications: [
        EnhancedCertification(nom: 'AWS Solutions Architect'),
      ], projects: [
        EnhancedProject(nom: 'App Mobile', technologies: 'Flutter'),
      ], languages: [
        EnhancedLanguage(langue: 'Anglais courant'),
      ]);

      final changes = diff(cv, enhanced);
      expect(forField(changes, EnhancementField.educationDiplome).single.after,
          'Master');
      expect(forField(changes, EnhancementField.educationEtablissement),
          isEmpty); // inchange
      expect(forField(changes, EnhancementField.certificationNom).single.after,
          'AWS Solutions Architect');
      expect(forField(changes, EnhancementField.projectNom).single.after,
          'App Mobile');
      expect(
          forField(changes, EnhancementField.projectTechnologies).single.after,
          'Flutter');
      expect(forField(changes, EnhancementField.language).single.after,
          'Anglais courant');
    });
  });
}
