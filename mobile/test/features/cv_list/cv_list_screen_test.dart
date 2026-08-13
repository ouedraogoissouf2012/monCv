import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/features/cv/application/state/cv_operation_state.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv_list/application/import_cv.dart';
import 'package:cv_mobile/features/cv_list/presentation/cv_list_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';

class MockCvStore extends Mock implements CvStore {}

class MockCvListController extends Mock implements CvListController {}

class MockCvEditorController extends Mock implements CvEditorController {}

Cv _fakeCv({int id = 1, String titre = 'CV Test'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
}

/// Use case d'import factice : l'import n'est pas exerce dans ces tests d'ecran
/// (couvert par import_cv_test / cv_list_controller_test).
ImportCvUseCase _fakeImport() =>
    ImportCvUseCase((bytes, filename) => throw UnimplementedError());

Widget _buildSubject(
  CvStore store,
  CvListController listController,
  CvEditorController editor,
) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CvStore>.value(value: store),
            Provider<CvListController>.value(value: listController),
            Provider<CvEditorController>.value(value: editor),
          ],
          child: CvListScreen(importCv: _fakeImport()),
        ),
      ),
      GoRoute(
        path: '/cvs/create',
        builder: (context, state) => const Scaffold(body: Text('Create CV')),
      ),
      GoRoute(
        path: '/cvs/:id',
        builder: (context, state) => const Scaffold(body: Text('CV Detail')),
      ),
      GoRoute(
        path: '/cvs/:id/edit',
        builder: (context, state) => const Scaffold(body: Text('CV Edit')),
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

void main() {
  late MockCvStore store;
  late MockCvListController listController;
  late MockCvEditorController editor;

  setUp(() {
    store = MockCvStore();
    listController = MockCvListController();
    editor = MockCvEditorController();

    when(() => store.cvs).thenReturn([]);
    when(() => store.state).thenReturn(const CvOperationState.idle());
    when(() => store.isOffline).thenReturn(false);
    when(() => store.addListener(any())).thenReturn(null);
    when(() => store.removeListener(any())).thenReturn(null);
    when(() => listController.load()).thenAnswer((_) async {});
  });

  Widget subject() => _buildSubject(store, listController, editor);

  group('CvListScreen (#249 D4)', () {
    testWidgets('affiche le titre Mes CVs dans l\'AppBar', (tester) async {
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.byType(CvListScreen), findsOneWidget);
      expect(find.text('Mes CVs'), findsWidgets);
    });

    testWidgets('affiche l\'etat vide quand il n\'y a pas de CVs',
        (tester) async {
      when(() => store.cvs).thenReturn([]);

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.text('Aucun CV pour l\'instant'), findsOneWidget);
      expect(find.text('Creez votre premier CV professionnel'), findsOneWidget);
    });

    testWidgets('affiche la liste des CVs quand il y en a', (tester) async {
      when(() => store.cvs).thenReturn([
        _fakeCv(id: 1, titre: 'CV Développeur'),
        _fakeCv(id: 2, titre: 'CV Designer'),
      ]);

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.text('CV Développeur'), findsOneWidget);
      expect(find.text('CV Designer'), findsOneWidget);
    });

    testWidgets('affiche les cartes CV en liste sur mobile sans overflow',
        (tester) async {
      _setMobileViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      when(() => store.cvs).thenReturn([
        _fakeCv(id: 1, titre: 'Architecte QA Web'),
      ]);

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Architecte QA Web'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un indicateur de chargement pendant loadCvs',
        (tester) async {
      when(() => store.state).thenReturn(const CvOperationState.loading());
      when(() => store.cvs).thenReturn([]);

      await tester.pumpWidget(subject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche le bouton Nouveau CV quand la liste est vide',
        (tester) async {
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.text('Nouveau CV'), findsWidgets);
    });
  });
}
