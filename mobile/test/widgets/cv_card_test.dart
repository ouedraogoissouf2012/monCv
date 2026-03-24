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
      ),
      experiences: [
        Experience(
          entreprise: 'Acme Corp',
          poste: 'Développeur',
        ),
      ],
    );

Cv _fakeCvIncomplete() => Cv(
      id: 2,
      titre: 'CV Incomplet',
    );

Widget _buildCard(Cv cv, {VoidCallback? onTap}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: CvCard(
        cv: cv,
        onTap: onTap ?? () {},
        onEdit: () {},
        onDownloadPdf: () {},
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

    testWidgets('affiche le badge Complet quand personalInfo et experience sont présents', (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.text('Complet'), findsOneWidget);
    });

    testWidgets('affiche le badge Incomplet quand il n\'y a ni personalInfo ni experiences', (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvIncomplete()));
      await tester.pump();

      expect(find.text('Incomplet'), findsOneWidget);
    });

    testWidgets('appelle onTap quand le bouton Voir est pressé', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildCard(_fakeCvComplete(), onTap: () {
        tapped = true;
      }));
      await tester.pump();

      await tester.tap(find.text('Voir'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
