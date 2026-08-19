import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/screens/cv/controllers/cv_form_controller.dart';
import 'package:cv_mobile/screens/cv/controllers/cv_wizard_draft_store.dart';
import 'package:cv_mobile/screens/cv/cv_form_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/di/injection_container.dart';
import 'package:cv_mobile/features/ai/application/generate_resume_usecase.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/cv/application/upload_profile_photo_usecase.dart';
import 'package:cv_mobile/features/cv/domain/repositories/profile_photo_repository.dart';

class MockCvListController extends Mock implements CvListController {}

class MockCvRepository extends Mock implements CvRepository {}

class _MockPhotoRepo extends Mock implements ProfilePhotoRepository {}

class _MockAiRepo extends Mock implements AiRepository {}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildSubject(
  CvListController listController, {
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

  return Provider<CvListController>.value(
    value: listController,
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
    // PersonalInfoSection resout ses use cases via le service locator quand
    // ils ne sont pas injectes : on les enregistre avec des repos mockes pour
    // que le montage de l'ecran ne leve pas (#242 D5b).
    final aiRepo = _MockAiRepo();
    when(() => aiRepo.generateResume(any(), any(), any()))
        .thenAnswer((_) async => const Result.success(''));
    if (!sl.isRegistered<UploadProfilePhotoUseCase>()) {
      sl.registerFactory(() => UploadProfilePhotoUseCase(_MockPhotoRepo()));
    }
    if (!sl.isRegistered<GenerateResumeUseCase>()) {
      sl.registerFactory(() => GenerateResumeUseCase(aiRepo));
    }
    if (!sl.isRegistered<CvWizardDraftStore>()) {
      sl.registerLazySingleton(CvWizardDraftStore.new);
    }
    if (!sl.isRegistered<CvStore>()) {
      sl.registerLazySingleton(CvStore.new);
    }
  });

  tearDownAll(() {
    if (sl.isRegistered<UploadProfilePhotoUseCase>()) {
      sl.unregister<UploadProfilePhotoUseCase>();
    }
    if (sl.isRegistered<GenerateResumeUseCase>()) {
      sl.unregister<GenerateResumeUseCase>();
    }
    if (sl.isRegistered<CvWizardDraftStore>()) {
      sl.unregister<CvWizardDraftStore>();
    }
    if (sl.isRegistered<CvStore>()) {
      sl.unregister<CvStore>();
    }
  });

  testWidgets('CvFormScreen mobile affiche la premiere etape sans exception',
      (tester) async {
    _setMobileViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);

    final listController = MockCvListController();
    final repository = MockCvRepository();
    final controller = CvFormController(
      repository: repository,
      fallbackTitle: 'Mon CV',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildSubject(
      listController,
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

    final listController = MockCvListController();
    final repository = MockCvRepository();
    final controller = CvFormController(
      repository: repository,
      fallbackTitle: 'Mon CV',
    );
    addTearDown(controller.dispose);
    when(() => listController.load()).thenAnswer((_) async {});
    when(() => repository.createCv(any())).thenAnswer(
      (invocation) async =>
          Result.success(invocation.positionalArguments.first as Cv),
    );

    await tester.pumpWidget(
      _buildSubject(
        listController,
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
    expect(
      find.text('Score ATS : ${controller.readinessScore}%'),
      findsOneWidget,
    );

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
