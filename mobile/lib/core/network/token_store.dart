import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Port d'acces au stockage des jetons d'authentification.
///
/// Injecte dans le transport (jamais instancie au point d'appel), il permet de
/// substituer une implementation en memoire dans les tests.
abstract interface class TokenStore {
  /// Jeton d'acces courant, ou `null` si l'utilisateur n'est pas connecte.
  Future<String?> readAccessToken();

  /// Jeton de rafraichissement courant, ou `null`.
  Future<String?> readRefreshToken();

  /// Persiste le couple de jetons apres une authentification reussie.
  Future<void> save({required String accessToken, required String refreshToken});

  /// Efface les jetons (deconnexion).
  Future<void> clear();
}

/// Adapter par defaut : [FlutterSecureStorage] (chiffrement OS) sur
/// mobile/desktop, memoire process sur web (le stockage securise n'y existe
/// pas). Les cles restent `access_token`/`refresh_token` pour rester compatible
/// avec les sessions ecrites par l'ancien `TokenStorage`.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final Map<String, String> _webMemory = {};

  @override
  Future<String?> readAccessToken() => _read(_accessKey);

  @override
  Future<String?> readRefreshToken() => _read(_refreshKey);

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _write(_accessKey, accessToken);
    await _write(_refreshKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) return _webMemory[key];
    return _storage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _webMemory[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _webMemory.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }
}
