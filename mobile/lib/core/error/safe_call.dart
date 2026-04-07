import 'dart:convert';
import 'result.dart';
import 'error_mapper.dart';

/// Enveloppe un appel async dans un Result<T>.
/// Convertit toute exception en AppException via ErrorMapper.
///
/// Usage dans un repository:
/// ```dart
/// Future<Result<List<Cv>>> getAllCvs() => safeCall(() => _api.getAllCvs());
/// ```
Future<Result<T>> safeCall<T>(Future<T> Function() call) async {
  try {
    final data = await call();
    return Result.success(data);
  } on AppException catch (e) {
    return Result.failure(e);
  } catch (e) {
    // Essayer de parser le message d'erreur Exception("message")
    final parsed = _tryParseHttpException(e);
    if (parsed != null) return Result.failure(parsed);

    return Result.failure(ErrorMapper.fromException(e));
  }
}

/// Tente d'extraire un code HTTP et un body JSON d'une Exception generique.
/// Les exceptions de ApiService sont du type Exception('Erreur...') ou
/// peuvent contenir le status code dans le message.
AppException? _tryParseHttpException(Object e) {
  final msg = e.toString();
  // Exception: {...json...}
  final jsonMatch = RegExp(r'Exception:\s*(\{.+\})').firstMatch(msg);
  if (jsonMatch != null) {
    try {
      final body = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
      final statusCode = body['status'] as int? ?? 400;
      return ErrorMapper.fromHttpResponse(statusCode, body);
    } catch (_) {}
  }
  return null;
}
