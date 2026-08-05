import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/features/cv_list/application/import_cv.dart';
import 'package:cv_mobile/features/cv_list/presentation/cv_list_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/providers/cv_provider.dart';

class MockCvProvider extends Mock implements CvProvider {}

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

Widget _buildSubject(CvProvider cvProvider) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => ChangeNotifierProvider<CvProvider>.value(
          value: cvProvider,
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
  late MockCvProvider mockCv;

  setUp(() {
    mockCv = MockCvProvider();

    when(() => mockCv.cvs).thenReturn([]);
    when(() => mockCv.isLoading).thenReturn(false);
    when(() => mockCv.isOffline).thenReturn(false);
    when(() => mockCv.error).thenReturn(null);
    when(() => mockCv.loadCvs()).thenAnswer((_) async {});
    when(() => mockCv.addListener(any())).thenReturn(null);
    when(() => mockCv.removeListener(any())).thenReturn(null);
  });

  group('CvListScreen (#249 D4)', () {
    testWidgets('affiche le titre Mes CVs dans l\'AppBar', (tester) async {
      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pumpAndSettle();

      expect(find.byType(CvListScreen), findsOneWidget);
      expect(find.text('Mes CVs'), findsWidgets);
    });

    testWidgets('affiche l\'etat vide quand il n\'y a pas de CVs',
        (tester) async {
      when(() => mockCv.cvs).thenReturn([]);

      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pumpAndSettle();

      expect(find.text('Aucun CV pour l\'instant'), findsOneWidget);
      expect(find.text('Creez votre premier CV professionnel'), findsOneWidget);
    });

    testWidgets('affiche la liste des CVs quand il y en a', (tester) async {
      when(() => mockCv.cvs).thenReturn([
        _fakeCv(id: 1, titre: 'CV Développeur'),
        _fakeCv(id: 2, titre: 'CV Designer'),
      ]);

      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pumpAndSettle();

      expect(find.text('CV Développeur'), findsOneWidget);
      expect(find.text('CV Designer'), findsOneWidget);
    });

    testWidgets('affiche les cartes CV en liste sur mobile sans overflow',
        (tester) async {
      _setMobileViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      when(() => mockCv.cvs).thenReturn([
        _fakeCv(id: 1, titre: 'Architecte QA Web'),
      ]);

      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Architecte QA Web'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un indicateur de chargement pendant loadCvs',
        (tester) async {
      when(() => mockCv.isLoading).thenReturn(true);
      when(() => mockCv.cvs).thenReturn([]);

      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche le bouton Nouveau CV quand la liste est vide',
        (tester) async {
      await tester.pumpWidget(_buildSubject(mockCv));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau CV'), findsWidgets);
    });
  });
}
