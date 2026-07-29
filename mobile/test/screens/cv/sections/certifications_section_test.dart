import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/certifications_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monte la section avec un etat mutable, renvoie l'accesseur de la liste.
  Future<List<Certification> Function()> pump(WidgetTester tester,
      {List<Certification> initial = const []}) async {
    var current = List<Certification>.of(initial);
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
          builder: (ctx, setState) => CertificationsSection(
            certifications: current,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    ));
    return () => current;
  }

  testWidgets('nom vide -> validation bloque la sauvegarde (#239 PR-C)',
      (tester) async {
    final read = await pump(tester);

    // Ouvre l'ajout.
    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    // Tente de sauvegarder sans nom : le validator doit bloquer.
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Le sheet reste ouvert (bouton de sauvegarde encore present) et rien
    // n'a ete ajoute a la liste.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Champ requis'), findsOneWidget);
    expect(read(), isEmpty);
  });

  testWidgets('nom renseigne -> certification ajoutee (#239 PR-C)',
      (tester) async {
    final read = await pump(tester);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'AWS SAA');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.nom, 'AWS SAA');
  });

  testWidgets('annulation -> liste inchangee (#239 PR-C)', (tester) async {
    final read = await pump(tester, initial: const [
      Certification(nom: 'Existante'),
    ]);

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Jetee');
    // Annule via le bouton Annuler (OutlinedButton).
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    final list = read();
    expect(list, hasLength(1));
    expect(list.first.nom, 'Existante');
  });

  testWidgets('suppression -> certification retiree (#239 PR-C)',
      (tester) async {
    final read = await pump(tester, initial: const [
      Certification(nom: 'A supprimer'),
    ]);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(read(), isEmpty);
  });
}
