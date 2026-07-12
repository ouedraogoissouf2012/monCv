import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/widgets/ai_enhance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

void main() {
  final cv = Cv(id: 42, titre: 'Community manager');

  testWidgets('le mode relecture affiche une action orthographique dédiée',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: AiEnhanceSheet(cv: cv, proofreadOnly: true),
      ),
    ));

    expect(find.text('Correction orthographique'), findsOneWidget);
    expect(find.text('Relire le CV'), findsOneWidget);
    expect(find.textContaining('J\'accepte que le contenu de ce CV'),
        findsOneWidget);
    expect(find.text('Medium'), findsNothing);
    expect(find.text('Max'), findsNothing);
    expect(find.byIcon(Icons.spellcheck_rounded), findsWidgets);
  });

  testWidgets('le mode amélioration conserve les trois niveaux',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: AiEnhanceSheet(cv: cv)),
    ));

    expect(find.text('Lite'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.textContaining('J\'accepte que le contenu de ce CV'),
        findsOneWidget);
  });
}
