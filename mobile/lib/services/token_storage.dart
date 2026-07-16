import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction du stockage de tokens compatible mobile et web.
///
/// - Sur mobile/desktop : [FlutterSecureStorage] (chiffrement OS)
/// - Sur web : [SharedPreferences] (localStorage)
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Map<String, String> _webMemory = {};

  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webMemory[key];
    }
    return _secureStorage.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _webMemory[key] = value;
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      _webMemory.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
}
