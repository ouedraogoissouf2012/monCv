import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/features/auth/presentation/register/register_screen.dart';
import 'package:cv_mobile/features/landing/presentation/landing_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _pumpAnimatedScreen(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: child,
  ));

  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  group('Responsive screens', () {
    testWidgets('LandingScreen mobile ne declenche pas de RenderFlex overflow',
        (tester) async {
      _setMobileViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpAnimatedScreen(tester, const LandingScreen());

      expect(find.text('Créer mon CV gratuitement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen mobile ne declenche pas de RenderFlex overflow',
        (tester) async {
      _setMobileViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final auth = MockAuthProvider();
      when(() => auth.isLoading).thenReturn(false);
      when(() => auth.error).thenReturn(null);
      when(() => auth.addListener(any())).thenReturn(null);
      when(() => auth.removeListener(any())).thenReturn(null);

      await _pumpAnimatedScreen(
        tester,
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const RegisterScreen(),
        ),
      );

      expect(find.text('Créer mon compte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
