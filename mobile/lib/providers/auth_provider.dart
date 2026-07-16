import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/error/result.dart';
import '../core/usecase/usecase.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';
import '../usecases/auth/login_usecase.dart';
import '../usecases/auth/register_usecase.dart';
import '../usecases/auth/logout_usecase.dart';
import '../usecases/auth/get_current_user_usecase.dart';
import '../usecases/auth/update_profile_usecase.dart';

class AuthProvider with ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthRepository _repository;
  final FlutterSecureStorage? _storage;
  final TokenStorage _tokenStorage;
  final Future<void> Function()? _clearLocalSessionData;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthRepository repository,
    FlutterSecureStorage? storage,
    TokenStorage? tokenStorage,
    Future<void> Function()? clearLocalSessionData,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _repository = repository,
        _storage = storage,
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _clearLocalSessionData = clearLocalSessionData {
    _checkAuthStatus();
  }

  User? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<String?> _readStoredAccessToken() {
    final storage = _storage;
    if (storage != null) {
      return storage.read(key: 'access_token');
    }
    return _tokenStorage.read('access_token');
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _readStoredAccessToken();
      if (token != null) {
        final result = await _getCurrentUserUseCase(const NoParams());
        switch (result) {
          case Success(:final data):
            _user = data;
            _isAuthenticated = true;
          case Failure():
            await _repository.clearTokens();
            _isAuthenticated = false;
        }
      }
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result =
        await _loginUseCase(LoginParams(email: email, password: password));
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        await _clearLocalSessionData?.call();
        _user = data.user;
        _isAuthenticated = true;
        _isCheckingAuth = false;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        _isCheckingAuth = false;
        notifyListeners();
        return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _registerUseCase(RegisterParams(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
    ));
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        await _clearLocalSessionData?.call();
        _user = data.user;
        _isAuthenticated = true;
        _isCheckingAuth = false;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        _isCheckingAuth = false;
        notifyListeners();
        return false;
    }
  }

  Future<void> logout() async {
    await _logoutUseCase(const NoParams());
    await _clearLocalSessionData?.call();
    _user = null;
    _isAuthenticated = false;
    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<void> updateProfile({String? nom, String? prenom}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _updateProfileUseCase(
        UpdateProfileParams(nom: nom, prenom: prenom));
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _user = data;
      case Failure(:final exception):
        _error = exception.message;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
