import 'dart:collection';

/// Verbe HTTP supporte par le pipeline transport.
enum HttpMethod { get, post, put, delete }

/// Description immuable d'une requete HTTP, independante de tout client.
///
/// Le [path] est concatene a `ApiConstants.baseUrl` par le transport ; il doit
/// donc commencer par `/` (ex. `/ai/enhance-cv`). Le corps [body] est un objet
/// JSON-encodable (Map/List/valeurs primitives) ; il est encode par le
/// transport, jamais ici.
class ApiRequest {
  final HttpMethod method;
  final String path;
  final Map<String, String> query;
  final Object? body;
  final bool withAuth;
  final Duration? timeout;

  const ApiRequest._({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
    required this.withAuth,
    required this.timeout,
  });

  /// Requete GET. Un corps n'est jamais envoye sur un GET.
  factory ApiRequest.get(
    String path, {
    Map<String, String> query = const {},
    bool withAuth = true,
    Duration? timeout,
  }) =>
      ApiRequest._(
        method: HttpMethod.get,
        path: path,
        query: _freeze(query),
        body: null,
        withAuth: withAuth,
        timeout: timeout,
      );

  /// Requete POST avec corps JSON-encodable optionnel.
  factory ApiRequest.post(
    String path, {
    Object? body,
    Map<String, String> query = const {},
    bool withAuth = true,
    Duration? timeout,
  }) =>
      ApiRequest._(
        method: HttpMethod.post,
        path: path,
        query: _freeze(query),
        body: body,
        withAuth: withAuth,
        timeout: timeout,
      );

  /// Requete PUT avec corps JSON-encodable optionnel.
  factory ApiRequest.put(
    String path, {
    Object? body,
    Map<String, String> query = const {},
    bool withAuth = true,
    Duration? timeout,
  }) =>
      ApiRequest._(
        method: HttpMethod.put,
        path: path,
        query: _freeze(query),
        body: body,
        withAuth: withAuth,
        timeout: timeout,
      );

  /// Requete DELETE avec corps JSON-encodable optionnel.
  factory ApiRequest.delete(
    String path, {
    Object? body,
    Map<String, String> query = const {},
    bool withAuth = true,
    Duration? timeout,
  }) =>
      ApiRequest._(
        method: HttpMethod.delete,
        path: path,
        query: _freeze(query),
        body: body,
        withAuth: withAuth,
        timeout: timeout,
      );

  static Map<String, String> _freeze(Map<String, String> query) =>
      query.isEmpty ? const {} : UnmodifiableMapView(Map.of(query));
}
