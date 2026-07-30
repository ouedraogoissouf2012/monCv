import 'package:cv_mobile/features/cv/presentation/personal_info/fields/country_autocomplete.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<String?> pump(WidgetTester tester,
      {String initial = ''}) async {
    String? lastChanged;
    final controller = TextEditingController(text: initial);
    addTearDown(controller.dispose);
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
        body: CountryAutocomplete(
          controller: controller,
          onChanged: (v) => lastChanged = v,
        ),
      ),
    ));
    return lastChanged;
  }

  testWidgets('saisie -> suggestions issues du catalogue (insensible accents)',
      (tester) async {
    await pump(tester);

    // "geor" (sans accent) doit proposer Georgie via le catalogue normalise.
    await tester.enterText(find.byKey(const Key('country-field')), 'geor');
    await tester.pumpAndSettle();

    expect(find.text('Géorgie'), findsOneWidget);
  });

  testWidgets('selection d une suggestion propage la valeur (#242 D3)',
      (tester) async {
    String? changed;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
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
        body: CountryAutocomplete(
          controller: controller,
          onChanged: (v) => changed = v,
        ),
      ),
    ));

    await tester.enterText(find.byKey(const Key('country-field')), 'burkina');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Burkina Faso').last);
    await tester.pumpAndSettle();

    expect(changed, 'Burkina Faso');
    expect(controller.text, 'Burkina Faso');
  });

  testWidgets('champ vide -> aucune suggestion parasite (#242 D3)',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('country-field')), '');
    await tester.pumpAndSettle();

    // Aucune ListTile de suggestion affichee pour une saisie vide.
    expect(find.byType(ListTile), findsNothing);
  });
}
