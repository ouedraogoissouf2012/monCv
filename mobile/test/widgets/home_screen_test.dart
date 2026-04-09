import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/l10n/app_localizations.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/screens/home/home_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockCvProvider extends Mock implements CvProvider {}

Cv _fakeCv({int id = 1, String titre = 'CV Test'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

User _fakeUser() => User(
      id: 1,
      email: 'user@test.com',
      nom: 'Doe',
      prenom: 'John',
      role: 'USER',
    );

Widget _buildSubject(AuthProvider authProvider, CvProvider cvProvider) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CvProvider>.value(value: cvProvider),
          ],
          child: const HomeScreen(),
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
  late MockAuthProvider mockAuth;
  late MockCvProvider mockCv;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockCv = MockCvProvider();

    when(() => mockAuth.user).thenReturn(_fakeUser());
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.addListener(any())).thenReturn(null);
    when(() => mockAuth.removeListener(any())).thenReturn(null);

    when(() => mockCv.cvs).thenReturn([]);
    when(() => mockCv.isLoading).thenReturn(false);
    when(() => mockCv.isOffline).thenReturn(false);
    when(() => mockCv.error).thenReturn(null);
    when(() => mockCv.loadCvs()).thenAnswer((_) async {});
    when(() => mockCv.addListener(any())).thenReturn(null);
    when(() => mockCv.removeListener(any())).thenReturn(null);
  });

  group('HomeScreen', () {
    testWidgets('affiche le titre Mes CVs dans l\'AppBar', (tester) async {
      await tester.pumpWidget(_buildSubject(mockAuth, mockCv));
      await tester.pumpAndSettle();

      expect(find.text('Mes CVs'), findsWidgets);
    });

    testWidgets('affiche l\'état vide quand il n\'y a pas de CVs', (tester) async {
      when(() => mockCv.cvs).thenReturn([]);

      await tester.pumpWidget(_buildSubject(mockAuth, mockCv));
      await tester.pumpAndSettle();

      expect(find.text('Aucun CV pour l\'instant'), findsOneWidget);
      expect(find.text('Creez votre premier CV professionnel'), findsOneWidget);
    });

    testWidgets('affiche la liste des CVs quand il y en a', (tester) async {
      when(() => mockCv.cvs).thenReturn([
        _fakeCv(id: 1, titre: 'CV Développeur'),
        _fakeCv(id: 2, titre: 'CV Designer'),
      ]);

      await tester.pumpWidget(_buildSubject(mockAuth, mockCv));
      await tester.pumpAndSettle();

      expect(find.text('CV Développeur'), findsOneWidget);
      expect(find.text('CV Designer'), findsOneWidget);
    });

    testWidgets('affiche un indicateur de chargement pendant loadCvs', (tester) async {
      when(() => mockCv.isLoading).thenReturn(true);
      when(() => mockCv.cvs).thenReturn([]);

      await tester.pumpWidget(_buildSubject(mockAuth, mockCv));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche le FAB Nouveau CV quand la liste est vide', (tester) async {
      await tester.pumpWidget(_buildSubject(mockAuth, mockCv));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau CV'), findsWidgets);
    });
  });
}
