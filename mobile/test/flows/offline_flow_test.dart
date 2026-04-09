import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
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

    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'fake-jwt');
    when(() => mockGetUser(any()))
        .thenAnswer((_) async => Result.success(fakeUser()));
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

  group('Offline Flow', () {
    testWidgets('perte de connexion → banner offline → retour en ligne → banner disparait',
        (tester) async {
      setTestScreenSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockGetAllCvs(any()))
          .thenAnswer((_) async => Result.success([fakeCv()]));

      final authProvider = buildAuthProvider();
      final cvProvider = buildCvProvider();

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        cvProvider: cvProvider,
        initialLocation: '/home',
      ));
      await tester.pumpAndSettle();

      // En ligne — pas de banner offline
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      // Simuler la perte de connexion
      connectivityCtrl.add(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Banner offline visible
      expect(cvProvider.isOffline, true);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Retour en ligne
      connectivityCtrl.add(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Banner disparait
      expect(cvProvider.isOffline, false);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    });
  });
}
