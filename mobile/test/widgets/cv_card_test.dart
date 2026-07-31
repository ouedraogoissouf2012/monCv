import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/cv_readiness_service.dart';
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
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      body: CvCard(
        cv: cv,
        onTap: onTap ?? () {},
        onEdit: () {},
        onDownloadPdf: () {},
        onDownloadDocx: () {},
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

    testWidgets('affiche le score de complétion en pourcentage',
        (tester) async {
      final cv = _fakeCvComplete();
      await tester.pumpWidget(_buildCard(cv));
      await tester.pump();

      // Le score doit s'afficher sous forme de pourcentage
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('le score affiche correspond a la preparation ATS',
        (tester) async {
      final cv = _fakeCvComplete();
      await tester.pumpWidget(_buildCard(cv));
      await tester.pump();

      final score = const CvReadinessService().evaluate(cv).score;
      expect(find.text('$score% ATS'), findsOneWidget);
    });

    test('CV incomplet obtient un score ATS faible', () {
      final cv = _fakeCvIncomplete();
      expect(const CvReadinessService().evaluate(cv).score, lessThan(50));
    });

    testWidgets('appelle onTap quand le bouton Voir est pressé',
        (tester) async {
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

    testWidgets('affiche directement le bouton de partage', (tester) async {
      bool shared = false;
      await tester.pumpWidget(
          _buildCard(_fakeCvComplete(), onShare: () => shared = true));
      await tester.pump();

      final directShareButton = find.byTooltip('Partager');
      expect(directShareButton, findsOneWidget);

      await tester.tap(directShareButton);
      await tester.pump();

      expect(shared, isTrue);
    });

    testWidgets('affiche la barre de progression', (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('CvCard partage & metadonnees', () {
    testWidgets('affiche le badge Vues quand le CV est partage',
        (tester) async {
      final sharedCv = Cv(
        id: 1,
        titre: 'CV Partage',
        shareToken: 'abc123',
        viewCount: 42,
        personalInfo:
            PersonalInfo(nom: 'Doe', prenom: 'John', email: 'j@e.com'),
        experiences: [Experience(entreprise: 'Acme', poste: 'Dev')],
      );
      await tester.pumpWidget(_buildCard(sharedCv));
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Vues'), findsOneWidget);
    });

    testWidgets('n\'affiche PAS le badge Vues quand le CV n\'est pas partage',
        (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.text('Vues'), findsNothing);
    });

    // ── Tests variantes ───────────────────────────────────────

    testWidgets('affiche le badge Variante quand isVariante est true',
        (tester) async {
      final variant = Cv(
        id: 20,
        titre: 'Mon CV — Dev Backend',
        varianteLabel: 'Dev Backend Java',
        parentCvId: 10,
      );
      await tester.pumpWidget(_buildCard(variant));
      await tester.pump();

      expect(find.textContaining('Variante'), findsOneWidget);
      expect(find.textContaining('Dev Backend Java'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('n\'affiche PAS le badge Variante pour un CV normal',
        (tester) async {
      await tester.pumpWidget(_buildCard(_fakeCvComplete()));
      await tester.pump();

      expect(find.byIcon(Icons.tune_rounded), findsNothing);
    });

    testWidgets('affiche le compteur variantes quand variantCount > 0',
        (tester) async {
      final parent = Cv(
        id: 10,
        titre: 'Mon CV Original',
        variantCount: 3,
        personalInfo:
            PersonalInfo(nom: 'Doe', prenom: 'John', email: 'j@e.com'),
        experiences: [Experience(entreprise: 'Acme', poste: 'Dev')],
      );
      await tester.pumpWidget(_buildCard(parent));
      await tester.pump();

      expect(find.text('3 variantes'), findsOneWidget);
    });
  });
}
