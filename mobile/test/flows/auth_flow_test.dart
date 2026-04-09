import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/screens/auth/login_screen.dart';
import 'package:cv_mobile/screens/home/home_screen.dart';

import 'helpers/mock_definitions.dart';
import 'helpers/fake_data.dart';
import 'helpers/test_app.dart';

void main() {
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUserUseCase mockGetUser;
  late MockUpdateProfileUseCase mockUpdateProfile;
  late MockAuthRepository mockAuthRepo;
  late MockFlutterSecureStorage mockStorage;

  late MockGetAllCvsUseCase mockGetAllCvs;
  late MockGetCvByIdUseCase mockGetCvById;
  late MockCreateCvUseCase mockCreateCv;
  late MockUpdateCvUseCase mockUpdateCv;
  late MockDeleteCvUseCase mockDeleteCv;
  late MockDuplicateCvUseCase mockDuplicate;
  late MockCvRepository mockCvRepo;
  late MockConnectivityService mockConnectivity;
  late StreamController<bool> connectivityCtrl;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetUser = MockGetCurrentUserUseCase();
    mockUpdateProfile = MockUpdateProfileUseCase();
    mockAuthRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();

    mockGetAllCvs = MockGetAllCvsUseCase();
    mockGetCvById = MockGetCvByIdUseCase();
    mockCreateCv = MockCreateCvUseCase();
    mockUpdateCv = MockUpdateCvUseCase();
    mockDeleteCv = MockDeleteCvUseCase();
    mockDuplicate = MockDuplicateCvUseCase();
    mockCvRepo = MockCvRepository();
    mockConnectivity = MockConnectivityService();
    connectivityCtrl = StreamController<bool>.broadcast();

    registerAllFallbackValues();

    when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => null);
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityCtrl.stream);

    suppressOverflowErrors();
  });

  tearDown(() => connectivityCtrl.close());

  AuthProvider buildAuthProvider() => AuthProvider(
        loginUseCase: mockLogin,
        registerUseCase: mockRegister,
        logoutUseCase: mockLogout,
        getCurrentUserUseCase: mockGetUser,
        updateProfileUseCase: mockUpdateProfile,
        repository: mockAuthRepo,
        storage: mockStorage,
      );

  CvProvider buildCvProvider() => CvProvider(
        getAllCvs: mockGetAllCvs,
        getCvById: mockGetCvById,
        createCv: mockCreateCv,
        updateCv: mockUpdateCv,
        deleteCv: mockDeleteCv,
        duplicateCv: mockDuplicate,
        repository: mockCvRepo,
        connectivity: mockConnectivity,
      );

  group('Auth Flow', () {
    testWidgets('login succes → navigation vers home → liste CVs visible',
        (tester) async {
      setTestScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      // Mock login → succes
      when(() => mockLogin(any()))
          .thenAnswer((_) async => Result.success(fakeAuthResponse()));

      // Mock liste CVs
      final cvs = [fakeCv(id: 1), fakeCv(id: 2, titre: 'CV Designer')];
      when(() => mockGetAllCvs(any()))
          .thenAnswer((_) async => Result.success(cvs));

      final authProvider = buildAuthProvider();
      final cvProvider = buildCvProvider();

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
      ));

      // LoginScreen s'affiche (redirection car non authentifie)
      await pumpPastAnimations(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('ADRESSE EMAIL'), findsOneWidget);

      // Remplir les champs
      await tester.enterText(
        find.widgetWithText(TextFormField, 'vous@exemple.com'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
        'password123',
      );

      // Tap Se connecter
      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
      await tester.pump();

      // Attendre la navigation vers home
      await tester.pumpAndSettle();

      // Verifier qu'on est sur HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verifier que les CVs sont affiches
      expect(find.text('CV Developpeur'), findsOneWidget);
      expect(find.text('CV Designer'), findsOneWidget);

      // Verifier l'etat du provider
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user?.email, 'test@example.com');
      expect(cvProvider.cvs.length, 2);
    });

    testWidgets('login echec → reste sur login → message erreur',
        (tester) async {
      setTestScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      // Mock login → echec
      when(() => mockLogin(any())).thenAnswer((_) async =>
          const Result.failure(AuthException(message: 'Email ou mot de passe incorrect')));

      final authProvider = buildAuthProvider();
      final cvProvider = buildCvProvider();

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
      ));

      await pumpPastAnimations(tester);

      // Remplir et soumettre
      await tester.enterText(
        find.widgetWithText(TextFormField, 'vous@exemple.com'),
        'wrong@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
        'badpassword',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));

      // Pump pour le traitement async
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Toujours sur LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Provider en etat erreur
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.error, isNotNull);
    });
  });
}
