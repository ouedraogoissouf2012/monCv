import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_detail_controller.dart' as cvp;
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart' as cvp;
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
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

  cvp.CvDetailController buildCvDetailController(CvStore store) =>
      cvp.CvDetailController(getCvById: mockGetCvById, store: store);

  group('CV Delete Flow', () {
    testWidgets('supprimer CV → dialog confirmation → CV disparait de la liste',
        (tester) async {
      setTestScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final cv = fakeCv(id: 1);
      when(() => mockGetAllCvs(any()))
          .thenAnswer((_) async => Result.success([cv]));
      when(() => mockDeleteCv(1))
          .thenAnswer((_) async => const Result.success(null));

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
        initialLocation: '/home',
      ));
      await tester.pumpAndSettle();

      // CV visible dans la liste
      expect(find.text('CV Developpeur'), findsOneWidget);

      // Ouvrir le menu contextuel du CvCard (icone more_vert)
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap l'action de suppression dans le menu, quel que soit le libelle
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Dialog de confirmation apparait
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirmer la suppression (FilledButton rouge)
      final deleteButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // CV supprime → liste vide
      expect(cvProvider.cvs, isEmpty);
      verify(() => mockDeleteCv(1)).called(1);
    });
  });
}
