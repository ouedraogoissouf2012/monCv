import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/cv_repository.dart';
import '../../repositories/cached_cv_repository.dart';
import '../../services/api_service.dart';
import '../../services/i_api_client.dart';
import '../../services/ai_service.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
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
import '../../providers/notification_provider.dart';
import '../../providers/job_application_provider.dart';
import '../../providers/ai_status_provider.dart';
import '../../services/push_notification_service.dart';
import '../../services/sync_queue.dart';

/// Instance globale du service locator.
final sl = GetIt.instance;

/// Initialise toutes les dependances.
/// Doit etre appele dans main() avant runApp().
Future<void> initDependencies() async {
  // ── External ──────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ── Services ──────────────────────────────────────────────────
  sl.registerLazySingleton<IApiClient>(() => ApiService());
  sl.registerLazySingleton<AiCvService>(() => AiCvService(sl<IApiClient>()));
  sl.registerLazySingleton<PdfService>(() => PdfService(sl<IApiClient>()));
  sl.registerLazySingleton<ShareService>(() => ShareService(sl<IApiClient>()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(sl<IApiClient>()));
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue(sl<SharedPreferences>()));

  // ── Repositories ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => HttpAuthRepository(api: sl<IApiClient>()),
  );
  sl.registerLazySingleton<CachedCvRepository>(
    () => CachedCvRepository(
      remote: HttpCvRepository(api: sl<IApiClient>()),
      prefs: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton<CvRepository>(() => sl<CachedCvRepository>());

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
  sl.registerFactory(() => EnhanceCvUseCase(sl<IApiClient>()));
  sl.registerFactory(() => MatchJobUseCase(sl<IApiClient>()));
  sl.registerFactory(() => GenerateResumeUseCase(sl<IApiClient>()));
  sl.registerFactory(() => SuggestBulletsUseCase(sl<IApiClient>()));

  // ── Providers ─────────────────────────────────────────────────
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
      syncQueue: sl<SyncQueue>(),
    ),
  );
  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
  sl.registerFactory<AiStatusProvider>(
      () => AiStatusProvider(api: sl<IApiClient>()));
  sl.registerFactory<NotificationProvider>(
      () => NotificationProvider(sl<IApiClient>()));
  sl.registerFactory<JobApplicationProvider>(
      () => JobApplicationProvider(sl<IApiClient>()));
}
