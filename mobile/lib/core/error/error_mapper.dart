import 'dart:async';
import 'dart:io';

import 'result.dart';

/// Convertit les exceptions HTTP et systeme en AppException typees.
/// Centralise le mapping pour eviter la duplication dans chaque repository.
class ErrorMapper {
  const ErrorMapper._();

  /// Mappe un status code HTTP + body en AppException.
  static AppException fromHttpResponse(int statusCode, Map<String, dynamic>? body) {
    final message = body?['message'] as String?;
    final code = body?['code'] as String?;

    return switch (statusCode) {
      400 => _mapValidationOrBusiness(body, message, code),
      401 => AuthException(
        message: message ?? 'Session expiree, veuillez vous reconnecter',
        code: code ?? 'AUTH_ERROR',
      ),
      403 => const AuthException(
        message: 'Acces non autorise',
        code: 'FORBIDDEN',
      ),
      404 => NotFoundException(
        message: message ?? 'Element non trouve',
      ),
      409 => ConflictException(
        message: message ?? 'Cet element existe deja',
      ),
      429 => const ServerException(
        message: 'Trop de requetes, veuillez patienter',
        code: 'RATE_LIMIT',
        statusCode: 429,
      ),
      // Erreurs IA (codes AI_*) renvoyees par le backend avec 502/503/504
      502 when _isAiErrorCode(code) => _mapAiError(body, code!),
      503 when _isAiErrorCode(code) => _mapAiError(body, code!),
      504 when _isAiErrorCode(code) => _mapAiError(body, code!),
      >= 500 => ServerException(
        message: message ?? 'Erreur serveur, veuillez reessayer',
        statusCode: statusCode,
      ),
      _ => ServerException(
        message: message ?? 'Erreur inattendue (code $statusCode)',
        statusCode: statusCode,
      ),
    };
  }

  static bool _isAiErrorCode(String? code) {
    return code != null && code.startsWith('AI_');
  }

  /// Traduit les codes backend AI_* en messages user-friendly.
  /// Remplace l'ancien "Mode hors ligne - cle DeepSeek manquante" trompeur.
  static AiException _mapAiError(Map<String, dynamic>? body, String code) {
    final details = body?['details'] as Map<String, dynamic>?;
    final provider = details?['provider'] as String?;
    final retryAfter = details?['retryAfter'] as int?;

    return switch (code) {
      'AI_KEY_INVALID' => AiException(
          code: 'AI_KEY_INVALID',
          provider: provider,
          message: "Le service IA est mal configure. Contactez l'administrateur."),
      'AI_QUOTA_EXCEEDED' => AiException(
          code: 'AI_QUOTA_EXCEEDED',
          provider: provider,
          retryAfterSeconds: retryAfter,
          message: retryAfter != null
              ? "Limite d'usage IA atteinte. Reessayez dans ${(retryAfter / 60).ceil()} min."
              : "Limite d'usage IA atteinte. Reessayez plus tard."),
      'AI_TIMEOUT' => AiException(
          code: 'AI_TIMEOUT',
          provider: provider,
          message: 'Le service IA met trop de temps a repondre. Reessayez.'),
      'AI_PROVIDER_DOWN' => AiException(
          code: 'AI_PROVIDER_DOWN',
          provider: provider,
          message: 'Le service IA est temporairement indisponible.'),
      'AI_PARSE_ERROR' => AiException(
          code: 'AI_PARSE_ERROR',
          provider: provider,
          message: 'Reponse IA invalide. Reessayez.'),
      _ => AiException(
          code: code,
          provider: provider,
          message: "Erreur du service IA"),
    };
  }

  /// Mappe une exception Dart brute en AppException.
  static AppException fromException(Object error) {
    if (error is AppException) return error;

    if (error is SocketException || error is HttpException) {
      return const NetworkException();
    }
    if (error is TimeoutException) {
      return const NetworkException(
        message: 'La requete a expire, verifiez votre connexion',
        code: 'TIMEOUT',
      );
    }
    if (error is FormatException) {
      return ServerException(
        message: 'Reponse serveur invalide',
        originalError: error,
      );
    }

    return ServerException(
      message: error.toString(),
      originalError: error,
    );
  }

  static AppException _mapValidationOrBusiness(
    Map<String, dynamic>? body,
    String? message,
    String? code,
  ) {
    final details = body?['details'];
    if (details is Map<String, dynamic>) {
      return ValidationException(
        message: message ?? 'Donnees invalides',
        fieldErrors: details.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    if (code == 'DUPLICATE_EMAIL') {
      return ConflictException(message: message ?? 'Cet email est deja utilise');
    }
    return ValidationException(message: message ?? 'Donnees invalides');
  }
}

/// Extension pour envelopper facilement un Future dans un Result.
extension FutureResultExtension<T> on Future<T> {
  /// Execute le Future et retourne Result.success ou Result.failure.
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }
}
