/// Type Result<T> pour representer le succes ou l'echec d'une operation.
/// Remplace les try/catch generiques par du pattern matching explicite.
///
/// Usage:
/// ```dart
/// final result = await repository.getCvs();
/// switch (result) {
///   case Success(:final data):
///     setState(() => cvs = data);
///   case Failure(:final exception):
///     showError(exception.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Cree un Result reussi avec les donnees.
  const factory Result.success(T data) = Success<T>;

  /// Cree un Result en echec avec l'exception.
  const factory Result.failure(AppException exception) = Failure<T>;

  /// Transforme les donnees si succes, propage l'erreur sinon.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Result.success(transform(data)),
    Failure(:final exception) => Result.failure(exception),
  };

  /// Extrait les donnees ou lance l'exception.
  T getOrThrow() => switch (this) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };

  /// Extrait les donnees ou retourne la valeur par defaut.
  T getOrElse(T defaultValue) => switch (this) {
    Success(:final data) => data,
    Failure() => defaultValue,
  };

  /// True si l'operation a reussi.
  bool get isSuccess => this is Success<T>;

  /// True si l'operation a echoue.
  bool get isFailure => this is Failure<T>;
}

/// Resultat reussi contenant les donnees.
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Resultat en echec contenant l'exception.
final class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Classe de base pour toutes les exceptions applicatives.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Erreur reseau (pas de connexion, timeout, DNS).
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Pas de connexion internet',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Erreur d'authentification (token expire, credentials invalides).
final class AuthException extends AppException {
  const AuthException({
    super.message = 'Session expiree, veuillez vous reconnecter',
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Erreur de validation (champs invalides, donnees manquantes).
final class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    super.message = 'Donnees invalides',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors = const {},
    super.originalError,
  });
}

/// Erreur serveur (500, API down, reponse inattendue).
final class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Erreur serveur, veuillez reessayer',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalError,
  });
}

/// Ressource non trouvee (404).
final class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Element non trouve',
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

/// Conflit (409 — email duplique, etc.).
final class ConflictException extends AppException {
  const ConflictException({
    super.message = 'Cet element existe deja',
    super.code = 'CONFLICT',
    super.originalError,
  });
}

/// Erreur specifique au sous-systeme IA.
/// Mappe les codes backend AI_* (AI_KEY_INVALID, AI_QUOTA_EXCEEDED, AI_TIMEOUT,
/// AI_PROVIDER_DOWN, AI_PARSE_ERROR) en messages user-friendly.
///
/// Remplace l'ancien message trompeur "Mode hors ligne - cle DeepSeek manquante"
/// qui s'affichait pour toutes les erreurs IA sans distinction.
final class AiException extends AppException {
  /// Nombre de secondes avant de pouvoir retenter (pour AI_QUOTA_EXCEEDED).
  final int? retryAfterSeconds;
  final String? provider;

  const AiException({
    required super.message,
    required String super.code,
    this.retryAfterSeconds,
    this.provider,
    super.originalError,
  });
}
