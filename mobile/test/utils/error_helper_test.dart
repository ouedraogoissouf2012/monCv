import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/utils/error_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Size size = const Size(400, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    final wide = snack.margin! as EdgeInsets;
    expect(wide.left, closeTo(410, 0.5));
    expect(wide.right, closeTo(410, 0.5));
  });

  testWidgets('snackbar s empile sur petit ecran', (tester) async {
    await pump(tester, size: const Size(320, 640));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Identifiants incorrects'), findsOneWidget);
    expect(find.text('Reessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    final narrow = snack.margin! as EdgeInsets;
    expect(narrow.left, 16);
    expect(narrow.right, 16);
  });
}
