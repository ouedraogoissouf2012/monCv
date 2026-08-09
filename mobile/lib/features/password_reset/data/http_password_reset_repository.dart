import '../../../core/error/result.dart';
import '../../../core/network/api_request.dart';
import '../../../core/network/api_transport.dart';
import '../../../utils/constants.dart';
import '../domain/password_reset_repository.dart';

/// Adaptateur HTTP de [PasswordResetRepository] (issue #381).
///
/// Passe par le pipeline [ApiTransport] (comme les features #237+), et NON par
/// la facade `ApiService` : le mot de passe oublie n'a pas a alourdir le
/// god-object vise par #232/#258. Les deux endpoints repondent 200 sans corps ;
/// toute erreur (reseau, 400 jeton invalide) est deja traduite en
/// [AppException] typee par le transport — on la convertit en [Result.failure].
///
/// [withAuth] est `false` : ces appels sont volontairement non authentifies
/// (l'utilisateur a justement perdu l'acces a son compte).
class HttpPasswordResetRepository implements PasswordResetRepository {
  HttpPasswordResetRepository(this._transport);

  final ApiTransport _transport;

  static const String _base = ApiConstants.authEndpoint;

  @override
  Future<Result<void>> requestReset(String email) =>
      _postNoContent('$_base/forgot-password', {'email': email});

  @override
  Future<Result<void>> confirmReset({
    required String token,
    required String newPassword,
  }) =>
      _postNoContent(
        '$_base/reset-password',
        {'token': token, 'newPassword': newPassword},
      );

  /// POST sans corps de reponse, statut 200 attendu. Le [Result] est construit a
  /// la main car `.toResult()` ne s'applique pas a `Future<void>`.
  Future<Result<void>> _postNoContent(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      await _transport.sendNoContent(
        ApiRequest.post(path, body: body, withAuth: false),
        ok: const {200},
      );
      return const Result.success(null);
    } on AppException catch (exception) {
      return Result.failure(exception);
    }
  }
}
