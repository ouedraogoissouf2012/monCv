import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/auth/presentation/login/login_screen.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_detail_controller.dart' as cvp;
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart' as cvp;
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/cv_list/presentation/cv_list_screen.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';

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
  late MockCreateVariantUseCase mockCreateVariant;
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
    mockCreateVariant = MockCreateVariantUseCase();
    mockCvRepo = MockCvRepository();
    mockConnectivity = MockConnectivityService();
    connectivityCtrl = StreamController<bool>.broadcast();

    registerAllFallbackValues();

    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => null);
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityCtrl.stream);
    when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);

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

  CvProvider buildCvProvider(CvStore store) => CvProvider(
        getAllCvs: mockGetAllCvs,
        getCvById: mockGetCvById,
        createCv: mockCreateCv,
        updateCv: mockUpdateCv,
        deleteCv: mockDeleteCv,
        duplicateCv: mockDuplicate,
        createVariantUseCase: mockCreateVariant,
        repository: mockCvRepo,
        connectivity: mockConnectivity,
        store: store,
      );

  cvp.CvListController buildCvListController(CvStore store) =>
      cvp.CvListController(getAllCvs: mockGetAllCvs, store: store);

  CvEditorController buildCvEditorController(CvStore store) =>
      CvEditorController(
        createCv: mockCreateCv,
        updateCv: mockUpdateCv,
        deleteCv: mockDeleteCv,
        duplicateCv: mockDuplicate,
        createVariant: mockCreateVariant,
        repository: mockCvRepo,
        store: store,
      );

  cvp.CvDetailController buildCvDetailController(CvStore store) =>
      cvp.CvDetailController(getCvById: mockGetCvById, store: store);

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
      final cvStore = CvStore();
      final cvProvider = buildCvProvider(cvStore);

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
        cvStore: cvStore,
        cvListController: buildCvListController(cvStore),
        cvEditorController: buildCvEditorController(cvStore),
        cvDetailController: buildCvDetailController(cvStore),
      ));

      // LoginScreen s'affiche (redirection car non authentifie)
      await pumpPastAnimations(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Remplir les champs
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      // Tap Se connecter
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Attendre la navigation vers home
      await tester.pumpAndSettle();

      // Verifier qu'on est sur l'ecran liste des CV
      expect(find.byType(CvListScreen), findsOneWidget);

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
      when(() => mockLogin(any())).thenAnswer((_) async => const Result.failure(
          AuthException(message: 'Email ou mot de passe incorrect')));

      final authProvider = buildAuthProvider();
      final cvStore = CvStore();
      final cvProvider = buildCvProvider(cvStore);

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
        cvStore: cvStore,
        cvListController: buildCvListController(cvStore),
        cvEditorController: buildCvEditorController(cvStore),
        cvDetailController: buildCvDetailController(cvStore),
      ));

      await pumpPastAnimations(tester);

      // Remplir et soumettre
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'wrong@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'badpassword',
      );
      await tester.tap(find.byType(ElevatedButton));

      // Pump pour le traitement async
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Toujours sur LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CvListScreen), findsNothing);

      // Provider en etat erreur
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.error, isNotNull);
    });
  });
}
