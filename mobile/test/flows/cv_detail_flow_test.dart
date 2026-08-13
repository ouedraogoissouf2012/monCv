import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart' as cvp;
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/widgets/cv_preview.dart';

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

    // Pre-authentifie : token present
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'fake-jwt');
    when(() => mockGetUser(any()))
        .thenAnswer((_) async => Result.success(fakeUser()));
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

  group('CV Detail Flow', () {
    testWidgets('tap CV dans la liste → preview + boutons export visibles',
        (tester) async {
      setTestScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final cv = fakeCv(id: 1);
      when(() => mockGetAllCvs(any()))
          .thenAnswer((_) async => Result.success([cv]));
      when(() => mockGetCvById(1)).thenAnswer((_) async => Result.success(cv));

      final authProvider = buildAuthProvider();
      final cvStore = CvStore();
      final cvProvider = buildCvProvider(cvStore);

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
        cvStore: cvStore,
        cvListController: buildCvListController(cvStore),
        cvEditorController: buildCvEditorController(cvStore),
        initialLocation: '/home',
      ));

      // Attendre que AuthProvider check le token et charge les CVs
      await tester.pumpAndSettle();

      // Tap sur l'action principale du CvCard, quel que soit le libelle
      final viewButton = find.byType(FilledButton);
      expect(viewButton, findsOneWidget);
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      // Verifier qu'on est sur CvDetailScreen avec le preview
      expect(find.byType(CvPreviewWidget), findsOneWidget);

      // Verifier les boutons d'action dans l'AppBar
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });
  });
}
