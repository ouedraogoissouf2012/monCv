import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/locale_provider.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocaleProvider utilise le francais par defaut', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = LocaleProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.locale, const Locale('fr'));
  });

  test('LocaleProvider change et persiste la langue', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = LocaleProvider();
    await provider.setLocale(const Locale('en'));

    expect(provider.locale, const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
  });

  testWidgets('le changement FR vers EN met a jour les textes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = LocaleProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) => MaterialApp(
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.login),
                    TextButton(
                      onPressed: () => provider.setLocale(const Locale('en')),
                      child: const Text('EN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('EN'));
    await tester.pump();
    expect(find.text('Log in'), findsOneWidget);
  });
}
