import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/widgets/cv_preview.dart';

Cv _fullCv() => Cv(
      id: 1,
      titre: 'Développeur Full Stack',
      personalInfo: PersonalInfo(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean@example.com',
        telephone: '0600000000',
        ville: 'Paris',
        pays: 'France',
        titrePoste: 'Lead Dev Flutter',
        resumeProfessionnel: 'Expert Flutter avec 5 ans d\'expérience.',
      ),
      experiences: [
        Experience(
          poste: 'Développeur Mobile',
          entreprise: 'TechCorp',
          lieu: 'Paris',
          actuel: true,
        ),
      ],
      educations: [
        Education(
          diplome: 'Master Informatique',
          etablissement: 'Université Paris',
        ),
      ],
      skills: [
        Skill(nom: 'Flutter', niveau: 5),
        Skill(nom: 'Dart', niveau: 4),
      ],
      languages: [
        Language(langue: 'Français', niveau: 'NATIF'),
        Language(langue: 'Anglais', niveau: 'C1'),
      ],
    );

Widget _buildPreview(Cv cv) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: CvPreviewWidget(cv: cv)),
    );

void main() {
  group('CvPreviewWidget', () {
    // Le template Moderne (defaut) affiche le nom en UPPERCASE
    testWidgets('affiche le nom complet', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('JEAN DUPONT'), findsOneWidget);
    });

    testWidgets('affiche le titre du poste', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('Lead Dev Flutter'), findsOneWidget);
    });

    // Le template Moderne utilise "PROFIL" comme section title
    testWidgets('affiche la section PROFIL quand resume renseigne', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('PROFIL'), findsOneWidget);
    });

    // Section title: "EXPERIENCES PROFESSIONNELLES"
    testWidgets('affiche la section EXPERIENCES', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('EXPERIENCES PROFESSIONNELLES'), findsOneWidget);
      expect(find.text('Développeur Mobile'), findsOneWidget);
    });

    testWidgets('affiche la section FORMATIONS', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('FORMATIONS'), findsOneWidget);
      expect(find.text('Master Informatique'), findsOneWidget);
    });

    testWidgets('affiche la section COMPETENCES', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('COMPETENCES'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('affiche la section LANGUES', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('LANGUES'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('n\'affiche pas les sections vides', (tester) async {
      final cv = Cv(titre: 'CV Vide');
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('EXPERIENCES PROFESSIONNELLES'), findsNothing);
      expect(find.text('FORMATIONS'), findsNothing);
      expect(find.text('COMPETENCES'), findsNothing);
      expect(find.text('LANGUES'), findsNothing);
    });

    // L'experience actuelle affiche "En cours" (pas "En poste")
    testWidgets('badge En cours visible pour experience actuelle', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.textContaining('En cours'), findsOneWidget);
    });

    testWidgets('affiche un header vide si pas de personalInfo', (tester) async {
      final cv = Cv(titre: 'Mon Super CV');
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      // Sans personalInfo, le nom est vide mais le widget se construit sans erreur
      expect(find.byType(CvPreviewWidget), findsOneWidget);
    });

    testWidgets('affiche la section CERTIFICATIONS', (tester) async {
      final cv = _fullCv().copyWith(certifications: [
        Certification(
          nom: 'AWS Certified Developer',
          organisme: 'Amazon',
          dateObtention: DateTime(2023, 6, 1),
        ),
      ]);
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('CERTIFICATIONS'), findsOneWidget);
      expect(find.text('AWS Certified Developer'), findsOneWidget);
    });

    testWidgets('affiche la section PROJETS', (tester) async {
      final cv = _fullCv().copyWith(projects: [
        Project(
          nom: 'MonCV App',
          technologies: 'Flutter, Dart',
          description: 'Application de creation de CV.',
        ),
      ]);
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('PROJETS'), findsOneWidget);
      expect(find.text('MonCV App'), findsOneWidget);
    });

    testWidgets('n\'affiche pas CERTIFICATIONS et PROJETS quand vides', (tester) async {
      final cv = Cv(titre: 'CV Vide');
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('CERTIFICATIONS'), findsNothing);
      expect(find.text('PROJETS'), findsNothing);
    });
  });
}
