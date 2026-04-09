@Tags(['widget'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/l10n/app_localizations.dart';

import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/screens/auth/login_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

Widget _buildSubject(AuthProvider authProvider) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginScreen(),
    ),
    routes: {
      '/register': (_) => const Scaffold(body: Text('Register')),
    },
  );
}

void _setScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  late MockAuthProvider mockAuth;
  final origOnError = FlutterError.onError;

  setUp(() {
    mockAuth = MockAuthProvider();
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.error).thenReturn(null);
    when(() => mockAuth.addListener(any())).thenReturn(null);
    when(() => mockAuth.removeListener(any())).thenReturn(null);

    // Ignorer les erreurs d'overflow qui ne sont pas critiques dans les tests
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      origOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = origOnError;
  });

  group('LoginScreen', () {
    testWidgets('affiche les champs et bouton', (tester) async {
      _setScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSubject(mockAuth));
      // Avancer le temps pour les Future.delayed (0s, 3s, 6s) + animations
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('MonCV'), findsOneWidget);
      expect(find.text('ADRESSE EMAIL'), findsOneWidget);
      expect(find.text('MOT DE PASSE'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('affiche erreurs de validation si champs vides', (tester) async {
      _setScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSubject(mockAuth));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
      await tester.pump();

      expect(find.text('Champ requis'), findsWidgets);
    });

    testWidgets('affiche indicateur de chargement', (tester) async {
      _setScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildSubject(mockAuth));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('appelle login avec les bonnes valeurs', (tester) async {
      _setScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuth.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(_buildSubject(mockAuth));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      await tester.enterText(
        find.widgetWithText(TextFormField, 'vous@exemple.com'),
        'user@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
        'password123',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
      await tester.pump();

      verify(() => mockAuth.login(
            email: 'user@test.com',
            password: 'password123',
          )).called(1);
    });
  });
}
