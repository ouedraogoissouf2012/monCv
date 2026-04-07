import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/widgets/cv_card.dart';

Cv _fakeCvComplete() => Cv(
      id: 1,
      titre: 'CV Test',
      personalInfo: PersonalInfo(
        nom: 'Doe',
        prenom: 'John',
        email: 'john@example.com',
        resumeProfessionnel: 'Expert Flutter.',
      ),
      experiences: [
        Experience(entreprise: 'Acme Corp', poste: 'Développeur'),
      ],
      educations: [
        Education(etablissement: 'Université Paris'),
      ],
      skills: [Skill(nom: 'Flutter', niveau: 4)],
      languages: [Language(langue: 'Français', niveau: 'NATIF')],
      certifications: [Certification(nom: 'AWS Certified')],
    );

Cv _fakeCvIncomplete() => Cv(id: 2, titre: 'CV Incomplet');

Widget _buildCard(
  Cv cv, {
  VoidCallback? onTap,
  VoidCallback? onDelete,
  VoidCallback? onDuplicate,
  VoidCallback? onShare,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: CvCard(
        cv: cv,
        onTap: onTap ?? () {},
        onEdit: () {},
        onDownloadPdf: () {},
        onDelete: onDelete ?? () {},
        onDuplicate: onDuplicate ?? () {},
        onShare: onShare ?? () {},
      ),
    ),
  );
}

void main() {
  group('CvCard', () {
    testWidgets('affiche le titre du CV', (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.text('CV Test'), findsOneWidget);
    });

    testWidgets('affiche le score de complétion en pourcentage', (tester) async {
      final cv = _fakeCvComplete();
      await tester.pumpWidget(_buildCard(cv));
      await tester.pump();

      // Le score doit s'afficher sous forme de pourcentage
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('CV complet affiche un score élevé (≥80%)', (tester) async {
      final cv = _fakeCvComplete();
      expect(cv.completionScore, greaterThanOrEqualTo(80));
    });

    testWidgets('CV incomplet affiche un score faible', (tester) async {
      final cv = _fakeCvIncomplete();
      expect(cv.completionScore, lessThan(50));
    });

    testWidgets('appelle onTap quand le bouton Voir est pressé', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
          _buildCard(_fakeCvComplete(), onTap: () => tapped = true));
      await tester.pump();

      await tester.tap(find.text('Voir'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('appelle onDelete via le menu contextuel', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
          _buildCard(_fakeCvComplete(), onDelete: () => deleted = true));
      await tester.pump();

      // Ouvre le popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tape sur Supprimer
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('appelle onDuplicate via le menu contextuel', (tester) async {
      bool duplicated = false;
      await tester.pumpWidget(
          _buildCard(_fakeCvComplete(), onDuplicate: () => duplicated = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dupliquer'));
      await tester.pumpAndSettle();

      expect(duplicated, isTrue);
    });

    testWidgets('appelle onShare via le menu contextuel', (tester) async {
      bool shared = false;
      await tester.pumpWidget(
          _buildCard(_fakeCvComplete(), onShare: () => shared = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Partager'));
      await tester.pumpAndSettle();

      expect(shared, isTrue);
    });

    testWidgets('affiche la barre de progression', (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('Cv.completionScore', () {
    test('titre seul = 10 pts', () {
      final cv = Cv(titre: 'Test');
      expect(cv.completionScore, 10);
    });

    test('titre + nom + prénom + email = 30 pts', () {
      final cv = Cv(
        titre: 'Test',
        personalInfo: PersonalInfo(
          nom: 'Doe',
          prenom: 'John',
          email: 'j@e.com',
        ),
      );
      expect(cv.completionScore, 30);
    });

    test('CV complet = 100 pts', () {
      final cv = Cv(
        titre: 'CV',
        personalInfo: PersonalInfo(
          nom: 'Doe',
          prenom: 'John',
          email: 'j@e.com',
          telephone: '0600',
          titrePoste: 'Dev',
          adresse: '1 rue',
          resumeProfessionnel: 'Expert.',
        ),
        experiences: [Experience(poste: 'Dev')],
        educations: [Education(etablissement: 'Univ')],
        skills: [Skill(nom: 'Flutter')],
        languages: [Language(langue: 'FR', niveau: 'NATIF')],
        certifications: [Certification(nom: 'AWS')],
        projects: [Project(nom: 'MonCV')],
      );
      expect(cv.completionScore, 100);
    });
  });
}
