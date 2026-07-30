import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/experience_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Experience> Function()> pump(WidgetTester tester,
      {List<Experience> initial = const []}) async {
    var current = List<Experience>.of(initial);
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
          builder: (ctx, setState) => ExperienceSection(
            experiences: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('poste + entreprise vides -> validation bloque (#239 PR-C3b)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // 2 champs requis -> 2 messages, sheet non ferme, rien ajoute.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsNWidgets(2));
    expect(read(), isEmpty);
  });

  testWidgets('poste + entreprise renseignes -> experience ajoutee',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Dev Flutter');
    await tester.enterText(find.byType(TextFormField).at(1), 'ACME');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.poste, 'Dev Flutter');
    expect(list.first.entreprise, 'ACME');
  });

  testWidgets('poste seul renseigne -> encore bloque par entreprise',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Dev');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // L'entreprise reste requise.
    expect(find.text('Champ requis'), findsOneWidget);
    expect(read(), isEmpty);
  });
}
