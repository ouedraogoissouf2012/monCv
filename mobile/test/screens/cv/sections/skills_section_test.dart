import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/domain/entities/skill.dart';
import 'package:cv_mobile/screens/cv/sections/skills_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Skill> Function()> pump(WidgetTester tester,
      {List<Skill> initial = const []}) async {
    var current = List<Skill>.of(initial);
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
          builder: (ctx, setState) => SkillsSection(
            skills: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('nom vide -> validation bloque la sauvegarde (#239 PR-C2)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsOneWidget);
    expect(read(), isEmpty);
  });

  testWidgets('nom renseigne -> competence ajoutee (niveau par defaut 3)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Dart');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.nom, 'Dart');
    expect(list.first.niveau, 3);
  });

  testWidgets('layout wrap : les competences sont dans un Wrap (#239 PR-C2)',
      (tester) async {
    await pump(tester, initial: const [
      Skill(nom: 'Java', niveau: 4),
      Skill(nom: 'Go', niveau: 2),
    ]);

    // EditableSectionList en mode wrap -> les items sont dans un Wrap.
    expect(find.byType(Wrap), findsWidgets);
    expect(find.text('Java'), findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('suppression -> competence retiree (#239 PR-C2)',
      (tester) async {
    final read = await pump(tester, initial: const [
      Skill(nom: 'A supprimer', niveau: 3),
    ]);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(read(), isEmpty);
  });
}
