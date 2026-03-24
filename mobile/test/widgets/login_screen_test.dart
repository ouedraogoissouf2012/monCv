import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/screens/auth/login_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

Widget _buildSubject(AuthProvider authProvider) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(body: Text('Register')),
      ),
    ],
  );

  return MaterialApp.router(
    theme: ThemeData(useMaterial3: true),
    routerConfig: router,
  );
}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.error).thenReturn(null);
    when(() => mockAuth.addListener(any())).thenReturn(null);
    when(() => mockAuth.removeListener(any())).thenReturn(null);
  });

  group('LoginScreen', () {
    testWidgets('affiche les champs email, mot de passe et bouton connexion',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSubject(mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('MonCV'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsWidgets);
    });

    testWidgets('affiche des erreurs de validation si les champs sont vides',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSubject(mockAuth));
      await tester.pumpAndSettle();

      // Tap le bouton connexion sans remplir les champs
      final loginButton = find.widgetWithText(FilledButton, 'Se connecter');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Champ requis'), findsWidgets);
    });

    testWidgets('affiche un indicateur de chargement pendant la connexion',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildSubject(mockAuth));
      await tester.pump(); // do not pumpAndSettle: CircularProgressIndicator animates forever

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('appelle login avec les bonnes valeurs quand le formulaire est valide',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuth.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(_buildSubject(mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password123',
      );

      final loginButton = find.widgetWithText(FilledButton, 'Se connecter');
      await tester.tap(loginButton);
      await tester.pump();

      verify(() => mockAuth.login(
            email: 'user@test.com',
            password: 'password123',
          )).called(1);
    });
  });
}
