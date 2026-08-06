import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/core/design_system/theme/app_theme_factory.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_modes.dart';
import 'package:cv_mobile/core/ui/confirm_dialog.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

/// Monte un bouton qui ouvre le dialog et enregistre son resultat dans [sink].
Future<void> _pumpOpener(
  WidgetTester tester,
  List<bool?> sink, {
  bool destructive = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppThemeFactory.build(AppThemeModes.minimal),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => sink.add(await showConfirmDialog(
            context,
            title: 'Titre',
            content: 'Contenu du message',
            confirmLabel: 'Confirmer',
            destructive: destructive,
          )),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche titre, contenu, confirmation et annulation',
      (tester) async {
    await _pumpOpener(tester, []);

    expect(find.text('Titre'), findsOneWidget);
    expect(find.text('Contenu du message'), findsOneWidget);
    expect(find.text('Confirmer'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('confirmer -> true et ferme le dialog', (tester) async {
    final results = <bool?>[];
    await _pumpOpener(tester, results);

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('annuler -> false et ferme le dialog', (tester) async {
    final results = <bool?>[];
    await _pumpOpener(tester, results);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('variante destructive : bouton de confirmation en danger',
      (tester) async {
    await _pumpOpener(tester, [], destructive: true);

    final button = tester.widget<FilledButton>(find.ancestor(
      of: find.text('Confirmer'),
      matching: find.byType(FilledButton),
    ));
    final danger = AppThemeModes.minimal.colorTokens.danger;
    expect(button.style?.backgroundColor?.resolve({}), danger);
  });
}
