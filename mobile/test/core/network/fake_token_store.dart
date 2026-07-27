import 'package:cv_mobile/core/network/token_store.dart';

/// [TokenStore] en memoire pour les tests : substituable a [SecureTokenStore]
/// (LSP) sans dependance au stockage securise de la plateforme.
class FakeTokenStore implements TokenStore {
  FakeTokenStore({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken;

  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
