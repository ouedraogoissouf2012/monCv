import 'package:get_it/get_it.dart';

import '../../../features/account/application/delete_account.dart';
import '../../../features/account/application/export_account_data.dart';
import '../../../features/account/data/http_account_repository.dart';
import '../../../features/account/domain/account_repository.dart';
import '../../../features/password_reset/application/confirm_password_reset.dart';
import '../../../features/password_reset/application/request_password_reset.dart';
import '../../../features/password_reset/data/http_password_reset_repository.dart';
import '../../../features/password_reset/domain/password_reset_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/cached_cv_repository.dart';
import '../../../services/i_api_client.dart';
import '../../../services/sync_queue.dart';
import '../../../usecases/auth/get_current_user_usecase.dart';
import '../../../usecases/auth/login_usecase.dart';
import '../../../usecases/auth/logout_usecase.dart';
import '../../../usecases/auth/register_usecase.dart';
import '../../../usecases/auth/update_profile_usecase.dart';
import '../../network/api_transport.dart';

/// Identite de l'utilisateur : session, compte et reinitialisation du mot de
/// passe.
///
/// [AuthProvider] purge les donnees locales a la deconnexion. Cette purge
/// touche le cache CV et la file de synchronisation, definis dans le module CV :
/// c'est la seule adherence entre les deux modules, et elle est resolue
/// paresseusement, donc insensible a l'ordre d'enregistrement.
void registerAuthModule(GetIt sl) {
  sl.registerLazySingleton<AuthRepository>(
    () => HttpAuthRepository(api: sl<IApiClient>()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => HttpAccountRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<PasswordResetRepository>(
    () => HttpPasswordResetRepository(sl<ApiTransport>()),
  );

  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => UpdateProfileUseCase(sl<AuthRepository>()));

  // Compte (issue #250).
  sl.registerFactory(() => ExportAccountDataUseCase(sl<AccountRepository>()));
  sl.registerFactory(() => DeleteAccountUseCase(sl<AccountRepository>()));

  // Reinitialisation du mot de passe (issue #381).
  sl.registerFactory(
      () => RequestPasswordResetUseCase(sl<PasswordResetRepository>()));
  sl.registerFactory(
      () => ConfirmPasswordResetUseCase(sl<PasswordResetRepository>()));

  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
      repository: sl<AuthRepository>(),
      clearLocalSessionData: () async {
        await sl<CachedCvRepository>().clearCache();
        await sl<SyncQueue>().clear();
      },
    ),
  );
}
