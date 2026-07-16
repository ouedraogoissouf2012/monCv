import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/repositories/auth_repository.dart';
import 'package:cv_mobile/usecases/auth/login_usecase.dart';
import 'package:cv_mobile/usecases/auth/register_usecase.dart';
import 'package:cv_mobile/usecases/auth/logout_usecase.dart';
import 'package:cv_mobile/usecases/auth/get_current_user_usecase.dart';
import 'package:cv_mobile/usecases/auth/update_profile_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

AuthResponse _fakeAuthResponse() => AuthResponse(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: User(
          id: 1,
          email: 'test@test.com',
          nom: 'Doe',
          prenom: 'John',
          role: 'USER'),
    );

User _fakeUser() => User(
    id: 1, email: 'test@test.com', nom: 'Doe', prenom: 'John', role: 'USER');

Future<void> _settleAuthCheck() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUserUseCase mockGetUser;
  late MockUpdateProfileUseCase mockUpdateProfile;
  late MockAuthRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;
  late int localCleanupCount;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetUser = MockGetCurrentUserUseCase();
    mockUpdateProfile = MockUpdateProfileUseCase();
    mockRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    localCleanupCount = 0;

    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const RegisterParams(email: '', password: ''));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const UpdateProfileParams());

    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => null);
  });

  AuthProvider buildProvider() => AuthProvider(
        loginUseCase: mockLogin,
        registerUseCase: mockRegister,
        logoutUseCase: mockLogout,
        getCurrentUserUseCase: mockGetUser,
        updateProfileUseCase: mockUpdateProfile,
        repository: mockRepo,
        storage: mockStorage,
        clearLocalSessionData: () async => localCleanupCount++,
      );

  group('AuthProvider', () {
    test('etat initial : non authentifie', () async {
      final provider = buildProvider();
      expect(provider.isCheckingAuth, true);

      await _settleAuthCheck();

      expect(provider.isAuthenticated, false);
      expect(provider.isCheckingAuth, false);
      expect(provider.isLoading, false);
      expect(provider.user, null);
    });

    test('restaure la session si un token existe', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'stored-token');
      when(() => mockGetUser(any()))
          .thenAnswer((_) async => Result.success(_fakeUser()));

      final provider = buildProvider();
      expect(provider.isCheckingAuth, true);

      await _settleAuthCheck();

      expect(provider.isCheckingAuth, false);
      expect(provider.isAuthenticated, true);
      expect(provider.user?.email, 'test@test.com');
      expect(localCleanupCount, 0);
      verify(() => mockGetUser(any())).called(1);
    });

    test('nettoie les tokens invalides apres echec de restauration', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'expired-token');
      when(() => mockGetUser(any())).thenAnswer(
        (_) async =>
            const Result.failure(AuthException(message: 'Token invalide')),
      );
      when(() => mockRepo.clearTokens())
          .thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();

      await _settleAuthCheck();

      expect(provider.isCheckingAuth, false);
      expect(provider.isAuthenticated, false);
      expect(provider.user, null);
      verify(() => mockRepo.clearTokens()).called(1);
    });

    test('login succes', () async {
      when(() => mockLogin(any()))
          .thenAnswer((_) async => Result.success(_fakeAuthResponse()));

      final provider = buildProvider();
      final result =
          await provider.login(email: 'test@test.com', password: 'pass');

      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(localCleanupCount, 1);
      expect(provider.user?.email, 'test@test.com');
    });

    test('login echec', () async {
      when(() => mockLogin(any())).thenAnswer((_) async => const Result.failure(
          AuthException(message: 'Email ou mot de passe incorrect')));

      final provider = buildProvider();
      final result = await provider.login(email: 'bad', password: 'wrong');

      expect(result, false);
      expect(provider.isAuthenticated, false);
      expect(provider.error, 'Email ou mot de passe incorrect');
    });

    test('register succes', () async {
      when(() => mockRegister(any()))
          .thenAnswer((_) async => Result.success(_fakeAuthResponse()));

      final provider = buildProvider();
      final result =
          await provider.register(email: 'new@test.com', password: 'pass');

      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(localCleanupCount, 1);
    });

    test('register echec', () async {
      when(() => mockRegister(any())).thenAnswer((_) async =>
          const Result.failure(
              ConflictException(message: 'Cet email est deja utilise')));

      final provider = buildProvider();
      final result = await provider.register(email: 'x', password: 'x');

      expect(result, false);
      expect(provider.error, 'Cet email est deja utilise');
    });

    test('logout', () async {
      when(() => mockLogin(any()))
          .thenAnswer((_) async => Result.success(_fakeAuthResponse()));
      when(() => mockLogout(any()))
          .thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();
      await provider.login(email: 'test@test.com', password: 'pass');
      expect(provider.isAuthenticated, true);

      await provider.logout();
      expect(provider.isAuthenticated, false);
      expect(provider.user, null);
      expect(localCleanupCount, 2);
    });

    test('clearError', () async {
      when(() => mockLogin(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Erreur')));

      final provider = buildProvider();
      await provider.login(email: 'x', password: 'x');
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, null);
    });
  });
}
