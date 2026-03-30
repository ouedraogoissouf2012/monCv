import '../models/user.dart';
import '../services/api_service.dart';

abstract class AuthRepository {
  Future<AuthResponse> login({required String email, required String password});
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  });
  Future<void> logout();
  Future<User> getCurrentUser();
  Future<void> clearTokens();
  Future<User> updateProfile({String? nom, String? prenom});
}

class HttpAuthRepository implements AuthRepository {
  final ApiService _api;

  HttpAuthRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<AuthResponse> login({required String email, required String password}) =>
      _api.login(email: email, password: password);

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) =>
      _api.register(email: email, password: password, nom: nom, prenom: prenom);

  @override
  Future<void> logout() => _api.logout();

  @override
  Future<User> getCurrentUser() => _api.getCurrentUser();

  @override
  Future<void> clearTokens() => _api.clearTokens();

  @override
  Future<User> updateProfile({String? nom, String? prenom}) =>
      _api.updateProfile(nom: nom, prenom: prenom);
}
