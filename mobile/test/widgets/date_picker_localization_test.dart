import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le sélecteur de date utilise la locale française',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 7, 11),
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Sélectionner une date'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
  });
}
