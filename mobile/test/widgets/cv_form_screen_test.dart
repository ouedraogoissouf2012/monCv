import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/screens/cv/controllers/cv_form_controller.dart';
import 'package:cv_mobile/screens/cv/cv_form_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/core/error/result.dart';

class MockCvProvider extends Mock implements CvProvider {}

class MockCvRepository extends Mock implements CvRepository {}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildSubject(
  CvProvider cvProvider, {
  required CvFormController controller,
  String initialLocation = '/cvs/create',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push('/cvs/create'),
              child: const Text('Ouvrir le formulaire'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/cvs/create',
        builder: (context, state) => CvFormScreen(controller: controller),
      ),
    ],
  );

  return ChangeNotifierProvider<CvProvider>.value(
    value: cvProvider,
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      routerConfig: router,
    ),
  );
}

Future<void> _enterFieldByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Cv(titre: 'Fallback'));
  });

  testWidgets('CvFormScreen mobile affiche la premiere etape sans exception',
      (tester) async {
    _setMobileViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);

    final cvProvider = MockCvProvider();
    final repository = MockCvRepository();
    final controller = CvFormController(
      repository: repository,
      fallbackTitle: 'Mon CV',
    );
    addTearDown(controller.dispose);
    when(() => cvProvider.addListener(any())).thenReturn(null);
    when(() => cvProvider.removeListener(any())).thenReturn(null);

    await tester.pumpWidget(_buildSubject(
      cvProvider,
      controller: controller,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau CV'), findsOneWidget);
    expect(find.text('Identite'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'CvFormScreen mobile sauvegarde depuis la derniere etape meme si identite est hors ecran',
      (tester) async {
    _setMobileViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);

    final cvProvider = MockCvProvider();
    final repository = MockCvRepository();
    final controller = CvFormController(
      repository: repository,
      fallbackTitle: 'Mon CV',
    );
    addTearDown(controller.dispose);
    when(() => cvProvider.addListener(any())).thenReturn(null);
    when(() => cvProvider.removeListener(any())).thenReturn(null);
    when(() => cvProvider.loadCvs()).thenAnswer((_) async {});
    when(() => repository.createCv(any())).thenAnswer(
      (invocation) async =>
          Result.success(invocation.positionalArguments.first as Cv),
    );

    await tester.pumpWidget(
      _buildSubject(
        cvProvider,
        controller: controller,
        initialLocation: '/home',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ouvrir le formulaire'));
    await tester.pumpAndSettle();

    await _enterFieldByLabel(tester, 'Prénom *', 'Smoke');
    await _enterFieldByLabel(tester, 'Nom *', 'Codex');
    await _enterFieldByLabel(tester, 'Email *', 'smoke@example.com');
    expect(find.text('Complétion : 20%'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Enregistrer le CV'));
    await tester.pumpAndSettle();

    verify(() => repository.createCv(any(
          that: isA<Cv>().having(
            (cv) => cv.personalInfo?.prenom,
            'prenom',
            'Smoke',
          ),
        ))).called(1);
    expect(find.text('Ouvrir le formulaire'), findsOneWidget);
  });
}
