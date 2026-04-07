import '../core/error/result.dart';
import '../core/error/safe_call.dart';
import '../models/user.dart';
import '../services/api_service.dart';

abstract class AuthRepository {
  Future<Result<AuthResponse>> login({required String email, required String password});
  Future<Result<AuthResponse>> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  });
  Future<Result<void>> logout();
  Future<Result<User>> getCurrentUser();
  Future<Result<void>> clearTokens();
  Future<Result<User>> updateProfile({String? nom, String? prenom});
}

class HttpAuthRepository implements AuthRepository {
  final ApiService _api;

  HttpAuthRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<Result<AuthResponse>> login({required String email, required String password}) =>
      safeCall(() => _api.login(email: email, password: password));

  @override
  Future<Result<AuthResponse>> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) =>
      safeCall(() => _api.register(email: email, password: password, nom: nom, prenom: prenom));

  @override
  Future<Result<void>> logout() => safeCall(() => _api.logout());

  @override
  Future<Result<User>> getCurrentUser() => safeCall(() => _api.getCurrentUser());

  @override
  Future<Result<void>> clearTokens() => safeCall(() => _api.clearTokens());

  @override
  Future<Result<User>> updateProfile({String? nom, String? prenom}) =>
      safeCall(() => _api.updateProfile(nom: nom, prenom: prenom));
}
