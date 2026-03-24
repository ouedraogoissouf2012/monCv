import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/screens/auth/login_screen.dart';
import 'package:cv_mobile/utils/constants.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

Widget _buildSubject(AuthProvider authProvider) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginScreen(),
    ),
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
      await tester.pumpWidget(_buildSubject(mockAuth));

      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.widgetWithText(TextFormField, AppStrings.email), findsOneWidget);
      expect(find.widgetWithText(TextFormField, AppStrings.password), findsOneWidget);
      expect(find.text(AppStrings.login), findsWidgets);
    });

    testWidgets('affiche des erreurs de validation si les champs sont vides',
        (tester) async {
      await tester.pumpWidget(_buildSubject(mockAuth));

      // Tap le bouton connexion sans remplir les champs
      final loginButton = find.widgetWithText(ElevatedButton, AppStrings.login);
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Veuillez entrer votre email'), findsOneWidget);
      expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
    });

    testWidgets('affiche un indicateur de chargement pendant la connexion',
        (tester) async {
      when(() => mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildSubject(mockAuth));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('appelle login avec les bonnes valeurs quand le formulaire est valide',
        (tester) async {
      when(() => mockAuth.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(_buildSubject(mockAuth));

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.email),
        'user@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.password),
        'password123',
      );

      final loginButton = find.widgetWithText(ElevatedButton, AppStrings.login);
      await tester.tap(loginButton);
      await tester.pump();

      verify(() => mockAuth.login(
            email: 'user@test.com',
            password: 'password123',
          )).called(1);
    });
  });
}
