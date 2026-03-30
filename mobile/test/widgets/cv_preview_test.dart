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
    testWidgets('affiche le nom complet', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('Jean Dupont'), findsOneWidget);
    });

    testWidgets('affiche le titre du poste', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('Lead Dev Flutter'), findsOneWidget);
    });

    testWidgets('affiche la section RÉSUMÉ quand renseigné', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('RÉSUMÉ PROFESSIONNEL'), findsOneWidget);
    });

    testWidgets('affiche la section EXPÉRIENCES', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('EXPÉRIENCES'), findsOneWidget);
      expect(find.text('Développeur Mobile'), findsOneWidget);
    });

    testWidgets('affiche la section FORMATIONS', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('FORMATIONS'), findsOneWidget);
      expect(find.text('Master Informatique'), findsOneWidget);
    });

    testWidgets('affiche la section COMPÉTENCES', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('COMPÉTENCES'), findsOneWidget);
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

      expect(find.text('EXPÉRIENCES'), findsNothing);
      expect(find.text('FORMATIONS'), findsNothing);
      expect(find.text('COMPÉTENCES'), findsNothing);
      expect(find.text('LANGUES'), findsNothing);
    });

    testWidgets('badge En poste visible pour expérience actuelle', (tester) async {
      await tester.pumpWidget(_buildPreview(_fullCv()));
      await tester.pump();

      expect(find.text('En poste'), findsOneWidget);
    });

    testWidgets('affiche le titre du CV si pas de nom', (tester) async {
      final cv = Cv(titre: 'Mon Super CV');
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('Mon Super CV'), findsOneWidget);
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
      expect(find.text('Amazon'), findsOneWidget);
    });

    testWidgets('affiche badge Expiré pour certification expirée', (tester) async {
      final cv = _fullCv().copyWith(certifications: [
        Certification(
          nom: 'Old Cert',
          organisme: 'Org',
          dateExpiration: DateTime(2020, 1, 1),
        ),
      ]);
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('Expiré'), findsOneWidget);
    });

    testWidgets('n\'affiche pas badge Expiré pour certification valide', (tester) async {
      final cv = _fullCv().copyWith(certifications: [
        Certification(
          nom: 'Valid Cert',
          dateExpiration: DateTime(2030, 1, 1),
        ),
      ]);
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('Expiré'), findsNothing);
    });

    testWidgets('affiche la section PROJETS', (tester) async {
      final cv = _fullCv().copyWith(projects: [
        Project(
          nom: 'MonCV App',
          technologies: 'Flutter, Dart',
          description: 'Application de création de CV.',
        ),
      ]);
      await tester.pumpWidget(_buildPreview(cv));
      await tester.pump();

      expect(find.text('PROJETS'), findsOneWidget);
      expect(find.text('MonCV App'), findsOneWidget);
      expect(find.text('Flutter, Dart'), findsOneWidget);
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
