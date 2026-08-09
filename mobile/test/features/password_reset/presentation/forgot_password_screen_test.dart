@Tags(['widget'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/password_reset/application/request_password_reset.dart';
import 'package:cv_mobile/features/password_reset/presentation/forgot_password_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';

class _MockRequestUseCase extends Mock implements RequestPasswordResetUseCase {}

Widget _subject(RequestPasswordResetUseCase useCase) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => ForgotPasswordScreen(requestReset: useCase),
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
  late _MockRequestUseCase useCase;
  final origOnError = FlutterError.onError;

  setUpAll(() =>
      registerFallbackValue(const RequestPasswordResetParams(email: '')));

  setUp(() {
    useCase = _MockRequestUseCase();
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      origOnError?.call(details);
    };
  });

  tearDown(() => FlutterError.onError = origOnError);

  void setSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('affiche le champ email et le bouton d\'envoi', (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_subject(useCase));
    await _settleAnimations(tester);

    expect(find.text('ADRESSE EMAIL'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Envoyer le lien'),
        findsOneWidget);
  });

  testWidgets('appelle le use case avec l\'email saisi', (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);
    when(() => useCase.call(any()))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(_subject(useCase));
    await _settleAnimations(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'vous@exemple.com'), 'user@test.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Envoyer le lien'));
    // Frames fixes : resout l'appel puis laisse le SnackBar de succes s'ecouler
    // (sinon un Timer reste actif a la fin du test).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    verify(() => useCase.call(any(
        that: isA<RequestPasswordResetParams>()
            .having((p) => p.email, 'email', 'user@test.com')))).called(1);
  });

  testWidgets('email vide -> aucun appel (validation locale)', (tester) async {
    setSize(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_subject(useCase));
    await _settleAnimations(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Envoyer le lien'));
    await tester.pump();

    verifyNever(() => useCase.call(any()));
    expect(find.text('Champ requis'), findsWidgets);
  });
}
