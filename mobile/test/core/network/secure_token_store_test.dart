import 'package:cv_mobile/core/network/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Exerce l'adapter reel SecureTokenStore sur la branche non-web
/// (FlutterSecureStorage injecte). kIsWeb est false en test.
void main() {
  late _MockSecureStorage storage;
  late SecureTokenStore store;

  setUp(() {
    storage = _MockSecureStorage();
    store = SecureTokenStore(storage: storage);
  });

  test('readAccessToken lit la cle access_token', () async {
    when(() => storage.read(key: 'access_token'))
        .thenAnswer((_) async => 'jwt-a');

    expect(await store.readAccessToken(), 'jwt-a');
    verify(() => storage.read(key: 'access_token')).called(1);
  });

  test('readRefreshToken lit la cle refresh_token', () async {
    when(() => storage.read(key: 'refresh_token'))
        .thenAnswer((_) async => 'jwt-r');

    expect(await store.readRefreshToken(), 'jwt-r');
  });

  test('save ecrit les deux cles historiques', () async {
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await store.save(accessToken: 'a', refreshToken: 'r');

    verify(() => storage.write(key: 'access_token', value: 'a')).called(1);
    verify(() => storage.write(key: 'refresh_token', value: 'r')).called(1);
  });

  test('clear supprime les deux cles', () async {
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    await store.clear();

    verify(() => storage.delete(key: 'access_token')).called(1);
    verify(() => storage.delete(key: 'refresh_token')).called(1);
  });
}
