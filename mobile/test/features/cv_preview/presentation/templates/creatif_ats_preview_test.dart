import 'package:cv_mobile/features/cv_preview/domain/cv_document_view_model.dart';
import 'package:cv_mobile/features/cv_preview/presentation/template/cv_preview_template.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/ats_preview.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/creatif_preview.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Cv sampleCv(String templateId) => Cv(
        titre: 'CV',
        style: CvStyle(templateId: templateId),
        personalInfo: const PersonalInfo(
          prenom: 'Issouf',
          nom: 'Ouedraogo',
          email: 'a@b.co',
          telephone: '+226 70 00 00 00',
          ville: 'Ouagadougou',
          titrePoste: 'Ingenieur logiciel',
          resumeProfessionnel: 'Un resume professionnel.',
        ),
        experiences: [const Experience(poste: 'Dev', entreprise: 'ACME')],
        skills: [const Skill(nom: 'Dart, Flutter', niveau: 4)],
        languages: [const Language(langue: 'Anglais', niveau: 'B2')],
      );

  Future<void> pump(
      WidgetTester tester, CvPreviewTemplate template, Cv cv) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(
        body: SingleChildScrollView(
          // Reproduit la contrainte de largeur du vrai CvPreviewWidget
          // (maxWidth 680) pour un rendu realiste.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Builder(
                builder: (context) =>
                    template.build(context, CvDocumentViewModel(cv)),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('CreatifPreviewTemplate (#243 E5)', () {
    test('id correct', () {
      expect(const CreatifPreviewTemplate().id, 'creatif');
    });

    testWidgets('sidebar (nom, competences eclatees) + colonne principale',
        (tester) async {
      await pump(tester, const CreatifPreviewTemplate(), sampleCv('creatif'));

      // Nom sur 2 lignes dans la sidebar : les 2 fragments sont presents.
      expect(find.textContaining('Issouf'), findsWidgets);
      // Competences eclatees en sidebar.
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      // Colonne principale : experience.
      expect(find.text('Dev'), findsOneWidget);
    });
  });

  group('AtsPreviewTemplate (#243 E5)', () {
    test('id correct', () {
      expect(const AtsPreviewTemplate().id, 'ats');
    });

    testWidgets('mono-colonne : nom, titre, contact, sections texte',
        (tester) async {
      await pump(tester, const AtsPreviewTemplate(), sampleCv('ats'));

      expect(find.text('Issouf Ouedraogo'), findsOneWidget);
      expect(find.text('Ingenieur logiciel'), findsOneWidget);
      // Competences rendues en ligne "nom (niveau)" -> pas de barres.
      expect(find.textContaining('Dart'), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });

    testWidgets('competences ATS rendues en une ligne texte (parsable)',
        (tester) async {
      await pump(tester, const AtsPreviewTemplate(), sampleCv('ats'));
      // Le rendu ATS concatene les competences avec " - " dans un seul Text.
      expect(find.textContaining('Dart'), findsOneWidget);
      expect(find.textContaining('Flutter'), findsOneWidget);
    });
  });
}
