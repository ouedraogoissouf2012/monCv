import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

AuthResponse _fakeAuthResponse() => AuthResponse(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: User(id: 1, email: 'test@test.com', nom: 'Doe', prenom: 'John', role: 'USER'),
    );

void main() {
  late MockAuthRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => null);
  });

  AuthProvider buildProvider() =>
      AuthProvider(repository: mockRepo, storage: mockStorage);

  group('AuthProvider', () {
    test('état initial : non authentifié, pas de chargement', () async {
      final provider = buildProvider();
      await Future.microtask(() {});
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.user, null);
    });

    test('login succès : isAuthenticated=true, user défini', () async {
      when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _fakeAuthResponse());

      final provider = buildProvider();
      final result = await provider.login(email: 'test@test.com', password: 'pass');

      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(provider.user?.email, 'test@test.com');
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('login échec : isAuthenticated=false, error défini', () async {
      when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('Email ou mot de passe incorrect'));

      final provider = buildProvider();
      final result = await provider.login(email: 'bad@test.com', password: 'wrong');

      expect(result, false);
      expect(provider.isAuthenticated, false);
      expect(provider.error, 'Email ou mot de passe incorrect');
      expect(provider.isLoading, false);
    });

    test('register succès : isAuthenticated=true', () async {
      when(() => mockRepo.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            nom: any(named: 'nom'),
            prenom: any(named: 'prenom'),
          )).thenAnswer((_) async => _fakeAuthResponse());

      final provider = buildProvider();
      final result = await provider.register(
        email: 'new@test.com',
        password: 'pass123',
        nom: 'Doe',
        prenom: 'Jane',
      );

      expect(result, true);
      expect(provider.isAuthenticated, true);
    });

    test('register échec : error défini', () async {
      when(() => mockRepo.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            nom: any(named: 'nom'),
            prenom: any(named: 'prenom'),
          )).thenThrow(Exception('Email déjà utilisé'));

      final provider = buildProvider();
      final result = await provider.register(
        email: 'exists@test.com',
        password: 'pass',
        nom: 'X',
        prenom: 'Y',
      );

      expect(result, false);
      expect(provider.error, 'Email déjà utilisé');
    });

    test('logout : remet isAuthenticated=false', () async {
      when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _fakeAuthResponse());
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      final provider = buildProvider();
      await provider.login(email: 'test@test.com', password: 'pass');
      expect(provider.isAuthenticated, true);

      await provider.logout();
      expect(provider.isAuthenticated, false);
      expect(provider.user, null);
    });

    test('clearError : remet error à null', () async {
      when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('Erreur'));

      final provider = buildProvider();
      await provider.login(email: 'x', password: 'x');
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, null);
    });
  });
}
