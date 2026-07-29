import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/languages_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Language> Function()> pump(WidgetTester tester,
      {List<Language> initial = const []}) async {
    var current = List<Language>.of(initial);
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
          builder: (ctx, setState) => LanguagesSection(
            languages: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('langue et niveau vides -> validation bloque (#239 PR-C2)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Langue requise + niveau requis -> 2 messages, sheet non ferme.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsNWidgets(2));
    expect(read(), isEmpty);
  });

  testWidgets('langue saisie mais niveau manquant -> sauvegarde bloquee',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    // Saisit la langue mais ne choisit PAS de niveau.
    await tester.enterText(find.byType(TextFormField).first, 'Anglais');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Le niveau (FormField) bloque : sheet ouvert, rien ajoute.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsOneWidget);
    expect(read(), isEmpty);
  });

  testWidgets('langue + niveau -> langue ajoutee (#239 PR-C2)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Anglais');
    // Choisit le niveau B2.
    await tester.tap(find.text('B2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.langue, 'Anglais');
    expect(list.first.niveau, 'B2');
  });

  testWidgets('suppression -> langue retiree (#239 PR-C2)', (tester) async {
    final read = await pump(tester, initial: const [
      Language(langue: 'Français', niveau: 'NATIF'),
    ]);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(read(), isEmpty);
  });
}
