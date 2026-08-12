import 'package:cv_mobile/features/cv_preview/presentation/cv_document_view_model.dart';
import 'package:cv_mobile/features/cv_preview/presentation/sections/cv_body_sections.dart';
import 'package:cv_mobile/features/cv_preview/presentation/sections/cv_entry_widgets.dart';
import 'package:cv_mobile/features/cv_preview/presentation/sections/cv_level_bars.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Cv cv) async {
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
          child: CvBodySections(
            document: CvDocumentViewModel(cv),
            accent: const Color(0xFF2563EB),
          ),
        ),
      ),
    ));
  }

  testWidgets('sections vides -> aucun titre orphelin (#243 E2)',
      (tester) async {
    await pump(tester, Cv(titre: 'x'));

    // Aucune section n'a de contenu -> aucun header ni entree.
    expect(find.byType(ExperienceEntry), findsNothing);
    expect(find.byType(EducationEntry), findsNothing);
    expect(find.byType(SkillLevelBars), findsNothing);
  });

  testWidgets('resume renseigne -> section PROFIL affichee (#243 E2)',
      (tester) async {
    await pump(
        tester,
        Cv(
          titre: 'x',
          personalInfo:
              const PersonalInfo(resumeProfessionnel: 'Mon resume pro.'),
        ));

    expect(find.text('Mon resume pro.'), findsOneWidget);
    expect(find.text('PROFIL'), findsOneWidget);
  });

  testWidgets('experiences + formations -> entrees rendues (#243 E2)',
      (tester) async {
    await pump(
        tester,
        Cv(titre: 'x', experiences: [
          const Experience(poste: 'Dev Flutter', entreprise: 'ACME'),
        ], educations: [
          const Education(diplome: 'Master', etablissement: 'ESI'),
        ]));

    expect(find.byType(ExperienceEntry), findsOneWidget);
    expect(find.byType(EducationEntry), findsOneWidget);
    expect(find.text('Dev Flutter'), findsOneWidget);
    expect(find.text('Master'), findsOneWidget);
  });

  testWidgets('competence multi-valuee -> eclatee en barres (#243 E2)',
      (tester) async {
    await pump(
        tester,
        Cv(titre: 'x', skills: [
          const Skill(nom: 'Java, Python', niveau: 4),
        ]));

    expect(find.byType(SkillLevelBars), findsOneWidget);
    expect(find.text('Java'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
  });

  testWidgets('date experience en cours -> libelle "En cours" (#243 E2)',
      (tester) async {
    await pump(
        tester,
        Cv(titre: 'x', experiences: [
          Experience(
              poste: 'Dev',
              actuel: true,
              dateDebut: DateTime(2022, 1)),
        ]));

    // formatDateRange doit produire "01/2022 - En cours".
    expect(find.textContaining('En cours'), findsOneWidget);
  });
}
