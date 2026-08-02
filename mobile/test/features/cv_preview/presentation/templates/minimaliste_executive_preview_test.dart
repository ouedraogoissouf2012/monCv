import 'package:cv_mobile/features/cv_preview/domain/cv_document_view_model.dart';
import 'package:cv_mobile/features/cv_preview/presentation/sections/cv_body_sections.dart';
import 'package:cv_mobile/features/cv_preview/presentation/template/cv_preview_template.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/executive_preview.dart';
import 'package:cv_mobile/features/cv_preview/presentation/templates/minimaliste_preview.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
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
          titrePoste: 'Developpeur Flutter',
          resumeProfessionnel: 'Un resume professionnel.',
        ),
        experiences: [const Experience(poste: 'Dev', entreprise: 'ACME')],
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
          child: Builder(
            builder: (context) =>
                template.build(context, CvDocumentViewModel(cv)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('MinimalistePreviewTemplate (#243 E4)', () {
    test('id correct', () {
      expect(const MinimalistePreviewTemplate().id, 'minimaliste');
    });

    testWidgets('affiche nom (casse normale), titre, contact et corps',
        (tester) async {
      await pump(
          tester, const MinimalistePreviewTemplate(), sampleCv('minimaliste'));

      expect(find.text('Issouf Ouedraogo'), findsOneWidget);
      expect(find.text('Developpeur Flutter'), findsOneWidget);
      expect(find.byType(CvBodySections), findsOneWidget);
      expect(find.text('PROFIL'), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });
  });

  group('ExecutivePreviewTemplate (#243 E4)', () {
    test('id correct', () {
      expect(const ExecutivePreviewTemplate().id, 'executive');
    });

    testWidgets('affiche nom, titre, contact (colonne droite) et corps',
        (tester) async {
      await pump(
          tester, const ExecutivePreviewTemplate(), sampleCv('executive'));

      expect(find.text('Issouf Ouedraogo'), findsOneWidget);
      expect(find.text('Developpeur Flutter'), findsOneWidget);
      expect(find.textContaining('a@b.co'), findsOneWidget);
      expect(find.byType(CvBodySections), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });
  });

  testWidgets('Executive applique la couleur d accent (barre + titre) (#243 E4)',
      (tester) async {
    final cv = sampleCv('executive').copyWith(
      style: const CvStyle(
          templateId: 'executive', primaryColor: Color(0xFF123456)),
    );
    await pump(tester, const ExecutivePreviewTemplate(), cv);

    final accentBars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color == const Color(0xFF123456));
    expect(accentBars, isNotEmpty);
  });
}
