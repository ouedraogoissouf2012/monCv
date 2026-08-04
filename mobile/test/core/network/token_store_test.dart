import 'package:cv_mobile/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_token_store.dart';

void main() {
  group('TokenStore (contrat)', () {
    // En test, kIsWeb est false : on ne peut pas exercer FlutterSecureStorage
    // sans plugin. On valide donc le contrat via le fake, qui partage la meme
    // interface. La persistance web reelle (localStorage) est couverte par
    // web_token_persistence_test.dart.
    late TokenStore store;

    setUp(() => store = FakeTokenStore());

    test('retourne null tant qu aucun jeton n est ecrit', () async {
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('save persiste le couple de jetons', () async {
      await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');
      expect(await store.readAccessToken(), 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
    });

    test('clear efface les deux jetons', () async {
      await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');
      await store.clear();
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('save ecrase les jetons precedents', () async {
      await store.save(accessToken: 'a1', refreshToken: 'r1');
      await store.save(accessToken: 'a2', refreshToken: 'r2');
      expect(await store.readAccessToken(), 'a2');
      expect(await store.readRefreshToken(), 'r2');
    });
  });

  test('SecureTokenStore s instancie avec les cles historiques', () {
    // Garantit que l adapter reel reste construisible sans plugin (aucune I/O).
    expect(SecureTokenStore.new, returnsNormally);
  });
}
