@Tags(['widget'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/password_reset/application/confirm_password_reset.dart';
import 'package:cv_mobile/features/password_reset/presentation/reset_password_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

class _MockConfirmUseCase extends Mock implements ConfirmPasswordResetUseCase {}

Widget _subject(ConfirmPasswordResetUseCase useCase, {String token = 'tok-123'}) {
  final router = GoRouter(
    initialLocation: '/reset-password/$token',
    routes: [
      GoRoute(
        path: '/reset-password/:token',
        builder: (_, state) => ResetPasswordScreen(
          token: state.pathParameters['token']!,
          confirmReset: useCase,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('LoginScreen')),
      ),
    ],
  );
  return MaterialApp.router(
    theme: ThemeData(useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    routerConfig: router,
  );
}

Future<void> _settleAnimations(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  late _MockConfirmUseCase useCase;
  final origOnError = FlutterError.onError;

  setUpAll(() => registerFallbackValue(
      const ConfirmPasswordResetParams(token: '', newPassword: '')));

  setUp(() {
    useCase = _MockConfirmUseCase();
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      origOnError?.call(details);
    };
  });

  tearDown(() => FlutterError.onError = origOnError);

  void setSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('affiche les champs et le bouton de réinitialisation',
      (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_subject(useCase));
    await _settleAnimations(tester);

    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(
        find.widgetWithText(ElevatedButton, 'Réinitialiser le mot de passe'),
        findsOneWidget);
  });

  testWidgets('mots de passe concordants -> appelle le use case avec le jeton '
      'de la route puis navigue vers /login', (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);
    when(() => useCase.call(any()))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(_subject(useCase, token: 'tok-xyz'));
    await _settleAnimations(tester);
    await tester.enterText(
        find.byType(TextFormField).at(0), 'NouveauMotDePasse1');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'NouveauMotDePasse1');
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Réinitialiser le mot de passe'));
    // Frames fixes (jamais pumpAndSettle : AuthShell anime en boucle) : laisse
    // l'appel se resoudre, la navigation s'operer et le SnackBar de succes
    // s'ecouler (evite un Timer encore actif a la fin du test).
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    verify(() => useCase.call(any(
            that: isA<ConfirmPasswordResetParams>()
                .having((p) => p.token, 'token', 'tok-xyz')
                .having((p) => p.newPassword, 'newPassword',
                    'NouveauMotDePasse1'))))
        .called(1);
    expect(find.text('LoginScreen'), findsOneWidget);
  });

  testWidgets('mots de passe différents -> aucun appel', (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_subject(useCase));
    await _settleAnimations(tester);
    await tester.enterText(
        find.byType(TextFormField).at(0), 'NouveauMotDePasse1');
    await tester.enterText(find.byType(TextFormField).at(1), 'Different1');
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Réinitialiser le mot de passe'));
    await tester.pump();

    verifyNever(() => useCase.call(any()));
    expect(find.text('Les mots de passe ne correspondent pas'), findsWidgets);
  });
}
