import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/web_token_persistence_stub.dart'
    if (dart.library.js_interop) '../core/network/web_token_persistence_web.dart';

/// Abstraction du stockage de tokens compatible mobile et web.
///
/// - Sur mobile/desktop : [FlutterSecureStorage] (chiffrement OS)
/// - Sur web : `localStorage` du navigateur (via [WebTokenPersistence]) — les
///   jetons SURVIVENT au rechargement de page (issue #359). Ils ne vivent plus
///   dans une Map en memoire de process.
///
/// Partage les cles `access_token`/`refresh_token` avec `SecureTokenStore`, si
/// bien que les deux adapters lisent la meme session web.
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final WebTokenPersistence _web = const WebTokenPersistence();

  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _web.read(key);
    }
    return _secureStorage.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _web.write(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      _web.delete(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
}
