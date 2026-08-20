import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/utils/error_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Size size = const Size(400, 800)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => ErrorHelper.showError(
                context, 'identifiants incorrects',
                onRetry: () {}),
            child: const Text('go'),
          );
        }),
      ),
    ));
  }

  testWidgets('snackbar affiche le message et Reessayer sans overflow',
      (tester) async {
    await pump(tester, size: const Size(1280, 800));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Identifiants incorrects'), findsOneWidget);
    expect(find.text('Reessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar s empile sur petit ecran', (tester) async {
    await pump(tester, size: const Size(320, 640));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Identifiants incorrects'), findsOneWidget);
    expect(find.text('Reessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
