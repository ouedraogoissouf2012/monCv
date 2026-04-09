import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/cv_repository.dart';
import '../../repositories/cached_cv_repository.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../usecases/auth/login_usecase.dart';
import '../../usecases/auth/register_usecase.dart';
import '../../usecases/auth/logout_usecase.dart';
import '../../usecases/auth/get_current_user_usecase.dart';
import '../../usecases/auth/update_profile_usecase.dart';
import '../../usecases/cv/get_all_cvs_usecase.dart';
import '../../usecases/cv/get_cv_by_id_usecase.dart';
import '../../usecases/cv/create_cv_usecase.dart';
import '../../usecases/cv/update_cv_usecase.dart';
import '../../usecases/cv/delete_cv_usecase.dart';
import '../../usecases/cv/duplicate_cv_usecase.dart';
import '../../usecases/cv/create_variant_usecase.dart';
import '../../usecases/ai/enhance_cv_usecase.dart';
import '../../usecases/ai/match_job_usecase.dart';
import '../../usecases/ai/generate_resume_usecase.dart';
import '../../usecases/ai/suggest_bullets_usecase.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/theme_provider.dart';

/// Instance globale du service locator.
final sl = GetIt.instance;

/// Initialise toutes les dependances.
/// Doit etre appele dans main() avant runApp().
Future<void> initDependencies() async {
  // ── External ──────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ── Services ──────────────────────────────────────────────────
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ── Repositories ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => HttpAuthRepository(api: sl<ApiService>()),
  );
  sl.registerLazySingleton<CvRepository>(
    () => CachedCvRepository(
      remote: HttpCvRepository(api: sl<ApiService>()),
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Use Cases: Auth ───────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => UpdateProfileUseCase(sl<AuthRepository>()));

  // ── Use Cases: CV ─────────────────────────────────────────────
  sl.registerFactory(() => GetAllCvsUseCase(sl<CvRepository>()));
  sl.registerFactory(() => GetCvByIdUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => UpdateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DeleteCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DuplicateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateVariantUseCase(sl<CvRepository>()));

  // ── Use Cases: AI ─────────────────────────────────────────────
  sl.registerFactory(() => EnhanceCvUseCase(sl<ApiService>()));
  sl.registerFactory(() => MatchJobUseCase(sl<ApiService>()));
  sl.registerFactory(() => GenerateResumeUseCase(sl<ApiService>()));
  sl.registerFactory(() => SuggestBulletsUseCase(sl<ApiService>()));

  // ── Providers ─────────────────────────────────────────────────
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
      repository: sl<AuthRepository>(),
    ),
  );
  sl.registerFactory<CvProvider>(
    () => CvProvider(
      getAllCvs: sl<GetAllCvsUseCase>(),
      getCvById: sl<GetCvByIdUseCase>(),
      createCv: sl<CreateCvUseCase>(),
      updateCv: sl<UpdateCvUseCase>(),
      deleteCv: sl<DeleteCvUseCase>(),
      duplicateCv: sl<DuplicateCvUseCase>(),
      createVariantUseCase: sl<CreateVariantUseCase>(),
      repository: sl<CvRepository>(),
      connectivity: sl<ConnectivityService>(),
    ),
  );
  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
}
