import 'package:cv_mobile/features/cv/presentation/section_editor/section_editor_sheet.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ouvre le sheet et renvoie le Future<T?> resultant (non-await : l'appelant
  // decide quand l'attendre, apres avoir tape sur un bouton du sheet).
  Future<Future<T?>> openSheet<T>(
    WidgetTester tester, {
    required T Function() buildResult,
    required Widget Function(BuildContext, StateSetter) content,
  }) async {
    late Future<T?> result;
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
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              result = showSectionEditor<T>(
                context: ctx,
                title: 'Titre',
                icon: Icons.edit,
                content: content,
                buildResult: buildResult,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('sauvegarde valide -> retourne le T construit (#239)',
      (tester) async {
    final result = await openSheet<String>(
      tester,
      buildResult: () => 'valeur-saisie',
      content: (ctx, setState) => const Text('contenu'),
    );

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(await result, 'valeur-saisie');
  });

  testWidgets('annulation -> retourne null (parent non modifie) (#239)',
      (tester) async {
    final result = await openSheet<String>(
      tester,
      buildResult: () => 'ne-doit-pas-revenir',
      content: (ctx, setState) => const Text('contenu'),
    );

    // Bouton Annuler (OutlinedButton).
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('fermeture (croix) -> retourne null (#239)', (tester) async {
    final result = await openSheet<String>(
      tester,
      buildResult: () => 'x',
      content: (ctx, setState) => const Text('contenu'),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('formulaire invalide -> ne ferme pas, buildResult non appele',
      (tester) async {
    var buildCalled = false;
    final result = await openSheet<String>(
      tester,
      buildResult: () {
        buildCalled = true;
        return 'x';
      },
      content: (ctx, setState) => TextFormField(
        validator: (v) => 'toujours invalide',
      ),
    );

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Le sheet reste ouvert (le contenu est encore visible) et le resultat
    // n'est pas encore produit.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(buildCalled, isFalse);

    // Nettoyage : fermer le sheet pour resoudre le Future.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
