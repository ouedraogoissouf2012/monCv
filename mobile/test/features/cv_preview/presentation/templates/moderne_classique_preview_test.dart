import 'package:cv_mobile/features/cv_preview/presentation/cv_document_view_model.dart';
import 'package:cv_mobile/features/cv_preview/presentation/sections/cv_body_sections.dart';
import 'package:cv_mobile/features/cv_preview/presentation/template/cv_preview_template.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/classique_preview.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/moderne_preview.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // CV realiste couvrant toutes les sections.
  Cv sampleCv() => Cv(
        titre: 'CV',
        style: const CvStyle(templateId: 'moderne'),
        personalInfo: const PersonalInfo(
          prenom: 'Alex',
          nom: 'Traore',
          email: 'a@b.co',
          telephone: '+226 70 00 00 00',
          ville: 'Ouagadougou',
          pays: 'Burkina Faso',
          titrePoste: 'Developpeur Flutter',
          resumeProfessionnel: 'Un resume professionnel.',
        ),
        experiences: [
          const Experience(poste: 'Dev', entreprise: 'ACME'),
        ],
        skills: [const Skill(nom: 'Dart', niveau: 4)],
      );

  Future<void> pump(WidgetTester tester, CvPreviewTemplate template, Cv cv) async {
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
          child: Builder(
            builder: (context) =>
                template.build(context, CvDocumentViewModel(cv)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('ModernePreviewTemplate (#243 E3)', () {
    test('id correct', () {
      expect(const ModernePreviewTemplate().id, 'moderne');
    });

    testWidgets('affiche nom (majuscules), titre, contact et corps',
        (tester) async {
      await pump(tester, const ModernePreviewTemplate(), sampleCv());

      // Moderne met le nom en UPPERCASE dans le bandeau.
      expect(find.text('ALEX TRAORE'), findsOneWidget);
      expect(find.text('Developpeur Flutter'), findsOneWidget);
      expect(find.textContaining('a@b.co'), findsOneWidget);
      // Corps commun present avec ses sections.
      expect(find.byType(CvBodySections), findsOneWidget);
      expect(find.text('PROFIL'), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });
  });

  group('ClassiquePreviewTemplate (#243 E3)', () {
    test('id correct', () {
      expect(const ClassiquePreviewTemplate().id, 'classique');
    });

    testWidgets('affiche nom (casse normale), titre et corps', (tester) async {
      await pump(tester, const ClassiquePreviewTemplate(), sampleCv());

      // Classique garde la casse d'origine (pas d'uppercase).
      expect(find.text('Alex Traore'), findsOneWidget);
      expect(find.text('Developpeur Flutter'), findsOneWidget);
      expect(find.byType(CvBodySections), findsOneWidget);
      expect(find.text('PROFIL'), findsOneWidget);
    });
  });

  testWidgets('template applique la couleur d accent du style (#243 E3)',
      (tester) async {
    final cv = sampleCv().copyWith(
      style: const CvStyle(
          templateId: 'classique', primaryColor: Color(0xFF123456)),
    );
    await pump(tester, const ClassiquePreviewTemplate(), cv);

    // La double barre d'accent utilise la couleur du style : au moins un
    // Container de cette couleur est present.
    final coloredBars = tester.widgetList<Container>(find.byType(Container)).where(
          (c) => c.color == const Color(0xFF123456),
        );
    expect(coloredBars, isNotEmpty);
  });
}
