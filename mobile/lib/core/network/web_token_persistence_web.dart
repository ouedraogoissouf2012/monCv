import 'package:web/web.dart' as web;

/// Persistance de jetons cote navigateur — implementation web.
///
/// Utilise `window.localStorage` : contrairement a une Map en memoire de
/// process, les jetons survivent a un rechargement de page (issue #359).
///
/// Note de securite : `localStorage` est lisible par tout script de l'origine
/// (surface XSS). C'est un compromis assume pour le web dev/preview ; la voie
/// durable (cookie httpOnly) est suivie hors de cette couche.
class WebTokenPersistence {
  const WebTokenPersistence();

  String? read(String key) => web.window.localStorage.getItem(key);

  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  void delete(String key) => web.window.localStorage.removeItem(key);
}
