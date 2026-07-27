import 'dart:convert';
import 'dart:typed_data';

/// Reponse HTTP normalisee retournee par le transport.
///
/// Ne construit aucun message localise et n'applique aucune logique metier :
/// elle expose le status, les entetes et le corps brut, plus des accesseurs
/// JSON qui levent [FormatException] si la forme attendue n'est pas respectee
/// (le transport traduit ensuite cette exception via `ErrorMapper`).
class ApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  /// Corps decode en UTF-8.
  String get body => utf8.decode(bodyBytes);

  /// Vrai pour un status 2xx.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Vrai pour un corps vide (ex. 204 No Content).
  bool get isEmpty => bodyBytes.isEmpty;

  /// Decode le corps en objet JSON, ou `null` si le corps est vide ou n'est pas
  /// un objet JSON valide. Utilise pour extraire un body d'erreur sans jamais
  /// lever : `ErrorMapper` fournit un message generique quand c'est `null`.
  Map<String, dynamic>? get jsonOrNull {
    if (isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Decode le corps en objet JSON. Leve [FormatException] si le corps est vide
  /// ou n'est pas un objet JSON (le transport la traduit en `ServerException`).
  Map<String, dynamic> get jsonObject {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Corps JSON attendu : objet');
    }
    return decoded;
  }

  /// Decode le corps en tableau JSON. Leve [FormatException] sinon.
  List<dynamic> get jsonArray {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('Corps JSON attendu : tableau');
    }
    return decoded;
  }
}
