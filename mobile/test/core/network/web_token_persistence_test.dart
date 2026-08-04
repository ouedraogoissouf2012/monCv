import 'package:cv_mobile/core/network/token_store.dart';
import 'package:cv_mobile/core/network/web_token_persistence_stub.dart';
import 'package:flutter_test/flutter_test.dart';

/// Persistance web simulee : reproduit `localStorage` (un magasin cle/valeur
/// partage par l'origine) au lieu d'une Map liee a une instance de store. C'est
/// ce partage qui permet aux jetons de survivre a un "rechargement" (nouvelle
/// instance de [SecureTokenStore]).
class _FakeLocalStorage implements WebTokenPersistence {
  final Map<String, String> backing;
  const _FakeLocalStorage(this.backing);

  @override
  String? read(String key) => backing[key];

  @override
  void write(String key, String value) => backing[key] = value;

  @override
  void delete(String key) => backing.remove(key);
}

void main() {
  group('SecureTokenStore branche web (localStorage) - #359', () {
    late Map<String, String> localStorage;
    SecureTokenStore webStore() => SecureTokenStore(
          isWeb: true,
          webPersistence: _FakeLocalStorage(localStorage),
        );

    setUp(() => localStorage = {});

    test('save ecrit dans localStorage, read le relit', () async {
      final store = webStore();
      await store.save(accessToken: 'jwt-a', refreshToken: 'jwt-r');

      expect(await store.readAccessToken(), 'jwt-a');
      expect(await store.readRefreshToken(), 'jwt-r');
      // Persiste hors de l'instance : localStorage contient les cles.
      expect(localStorage['access_token'], 'jwt-a');
      expect(localStorage['refresh_token'], 'jwt-r');
    });

    test('le jeton SURVIT a un rechargement (nouvelle instance)', () async {
      // Session 1 : login.
      await webStore().save(accessToken: 'jwt-a', refreshToken: 'jwt-r');

      // Rechargement de page : une NOUVELLE instance de store est creee, mais
      // localStorage (le backing partage) subsiste — c'est le fix de #359.
      final afterReload = webStore();

      expect(await afterReload.readAccessToken(), 'jwt-a',
          reason: 'le jeton doit survivre au reload, plus de Map en memoire');
      expect(await afterReload.readRefreshToken(), 'jwt-r');
    });

    test('clear efface localStorage (deconnexion)', () async {
      final store = webStore();
      await store.save(accessToken: 'jwt-a', refreshToken: 'jwt-r');

      await store.clear();

      expect(await store.readAccessToken(), isNull);
      expect(localStorage, isEmpty);
    });
  });
}
