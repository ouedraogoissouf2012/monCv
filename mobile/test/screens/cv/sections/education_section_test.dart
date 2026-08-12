import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/domain/entities/education.dart';
import 'package:cv_mobile/screens/cv/sections/education_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Education> Function()> pump(WidgetTester tester,
      {List<Education> initial = const []}) async {
    var current = List<Education>.of(initial);
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
        body: StatefulBuilder(
          builder: (ctx, setState) => EducationSection(
            educations: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('etablissement/diplome vides -> validation bloque (#239 PR-C)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Deux champs requis -> deux messages de validation, sheet non ferme.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsNWidgets(2));
    expect(read(), isEmpty);
  });

  testWidgets('champs requis renseignes -> formation ajoutee (#239 PR-C)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    // 1er champ = etablissement, 2e = diplome (ordre de la Column).
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Universite X');
    await tester.enterText(find.byType(TextFormField).at(1), 'Master');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.etablissement, 'Universite X');
    expect(list.first.diplome, 'Master');
  });

  testWidgets(
      'formation existante sans dateFin -> case « en cours » cochee (#239 PR-C)',
      (tester) async {
    // Regression : l'ancien code forcait enCours a false. Une formation sans
    // date de fin doit rouvrir avec la case cochee.
    await pump(tester, initial: [
      const Education(etablissement: 'ESI', diplome: 'Licence'),
    ]);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    final checkbox =
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(checkbox.value, isTrue);
  });
}
