import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'web_token_persistence_stub.dart'
    if (dart.library.js_interop) 'web_token_persistence_web.dart';

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
/// mobile/desktop, `localStorage` du navigateur sur web (via
/// [WebTokenPersistence]). Les cles restent `access_token`/`refresh_token` pour
/// rester compatible avec les sessions ecrites par l'ancien `TokenStorage`.
///
/// Sur web, les jetons SURVIVENT au rechargement de page (issue #359) : ils ne
/// vivent plus dans une Map en memoire de process, mais dans `localStorage`.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    WebTokenPersistence webPersistence = const WebTokenPersistence(),
    bool? isWeb,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _web = webPersistence,
        _isWeb = isWeb ?? kIsWeb;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final WebTokenPersistence _web;

  /// Aiguillage web vs securise. Par defaut [kIsWeb] ; surchargeable en test
  /// pour exercer la branche `localStorage` sans navigateur.
  final bool _isWeb;

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
    if (_isWeb) return _web.read(key);
    return _storage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (_isWeb) {
      _web.write(key, value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> _delete(String key) async {
    if (_isWeb) {
      _web.delete(key);
    } else {
      await _storage.delete(key: key);
    }
  }
}
