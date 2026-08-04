/// Persistance de jetons cote navigateur — implementation par defaut (non-web).
///
/// Sur mobile/desktop, [SecureTokenStore] utilise `FlutterSecureStorage` et
/// n'appelle jamais cette facade ; ces methodes ne sont donc que des stubs
/// inertes, presents pour satisfaire l'import conditionnel.
class WebTokenPersistence {
  const WebTokenPersistence();

  String? read(String key) => null;

  void write(String key, String value) {}

  void delete(String key) {}
}
