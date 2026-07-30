import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/projects_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Project> Function()> pump(WidgetTester tester,
      {List<Project> initial = const []}) async {
    var current = List<Project>.of(initial);
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
          builder: (ctx, setState) => ProjectsSection(
            projects: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('nom vide -> validation bloque la sauvegarde (#239 PR-C3b)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsOneWidget);
    expect(read(), isEmpty);
  });

  testWidgets('nom renseigne -> projet ajoute (#239 PR-C3b)', (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Mon portfolio');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.nom, 'Mon portfolio');
  });

  testWidgets('suppression -> projet retire (#239 PR-C3b)', (tester) async {
    final read = await pump(tester, initial: const [
      Project(nom: 'A supprimer'),
    ]);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(read(), isEmpty);
  });
}
