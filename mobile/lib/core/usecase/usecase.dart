import '../error/result.dart';

/// Contrat de base pour tous les use cases.
/// Chaque use case a une seule methode [call] qui prend des [Params]
/// et retourne un [Result<T>].
///
/// Usage:
/// ```dart
/// class LoginUseCase implements UseCase<AuthResponse, LoginParams> {
///   Future<Result<AuthResponse>> call(LoginParams params) => ...
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Pour les use cases sans parametres.
class NoParams {
  const NoParams();
}
