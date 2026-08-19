// Cable la facade AiCvService @Deprecated (transitoire, retiree par #245).
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/account/application/delete_account.dart';
import '../../features/account/application/export_account_data.dart';
import '../../features/account/data/http_account_repository.dart';
import '../../features/account/domain/account_repository.dart';
import '../../features/notifications/data/http_notification_settings_repository.dart';
import '../../features/notifications/domain/notification_settings_repository.dart';
import '../../features/cv_share/data/http_cv_share_repository.dart';
import '../../features/cv_share/domain/cv_share_repository.dart';
import '../../features/media/data/http_secure_photo_repository.dart';
import '../../features/media/domain/secure_photo_repository.dart';
import '../../features/public_portfolio/data/http_public_portfolio_repository.dart';
import '../../features/public_portfolio/domain/public_portfolio_repository.dart';
import '../../features/password_reset/application/confirm_password_reset.dart';
import '../../features/password_reset/application/request_password_reset.dart';
import '../../features/password_reset/data/http_password_reset_repository.dart';
import '../../features/password_reset/domain/password_reset_repository.dart';
import '../../features/ai/application/enhance_cv_usecase.dart';
import '../../features/cv/application/upload_profile_photo_usecase.dart';
import '../../features/cv/data/http_profile_photo_repository.dart';
import '../../features/cv/domain/repositories/profile_photo_repository.dart';
import '../../utils/constants.dart';
import '../../screens/cv/controllers/cv_wizard_draft_store.dart';
import '../../features/ai/application/generate_application_messages_usecase.dart';
import '../../features/application_messages/data/system_clipboard_copier.dart';
import '../../features/application_messages/domain/clipboard_copier.dart';
import '../../features/ai/application/generate_resume_usecase.dart';
import '../../features/ai/application/get_ai_status_usecase.dart';
import '../../features/ai/application/match_job_usecase.dart';
import '../../features/ai/application/suggest_bullets_usecase.dart';
import '../../features/ai/compat/ai_service_facade.dart';
import '../../features/ai/data/ai_remote_data_source.dart';
import '../../features/ai/data/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/cv_repository.dart';
import '../../repositories/cv_trash_repository.dart';
import '../../repositories/cv_trash_repository.dart';
import '../../repositories/cached_cv_repository.dart';
import '../../services/api_service.dart';
import '../../services/i_api_client.dart';
import '../../services/pdf_service.dart';
import '../network/api_transport.dart';
import '../network/multipart_transport.dart';
import '../network/session_refresher.dart';
import '../network/token_store.dart';
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
import '../../providers/auth_provider.dart';
import '../../features/cv/application/sync/offline_cv_sync_coordinator.dart';
import '../../features/cv/presentation/controllers/cv_connectivity_sync_controller.dart';
import '../../features/cv/presentation/controllers/cv_detail_controller.dart' as cvp;
import '../../features/cv/presentation/controllers/cv_editor_controller.dart';
import '../../features/cv/presentation/controllers/cv_list_controller.dart';
import '../../features/cv/presentation/controllers/cv_style_controller.dart' as cvp;
import '../../features/cv/presentation/cv_store.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../features/applications/application/delete_application.dart';
import '../../features/cv_detail/presentation/cv_detail_controller.dart';
import '../../features/cv_export/application/export_cv_docx.dart';
import '../../features/cv_export/application/export_cv_pdf.dart';
import '../../features/applications/application/list_applications.dart';
import '../../features/applications/application/save_application.dart';
import '../../features/applications/data/application_remote_data_source.dart';
import '../../features/applications/data/application_repository_impl.dart';
import '../../features/applications/data/url_launcher_link_launcher.dart';
import '../../features/applications/domain/application_repository.dart';
import '../../features/applications/domain/external_link_launcher.dart';
import '../../features/applications/presentation/application_list_controller.dart';
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

  // ── Transport reseau (issue #237) ─────────────────────────────
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<TokenStore>(() => SecureTokenStore());
  // Refresh de session single-flight sur 401 (issue M-7). Singleton : l'etat
  // "refresh en cours" est partage par toutes les requetes du pipeline.
  sl.registerLazySingleton<SessionRefresher>(
      () => HttpSessionRefresher(sl<http.Client>(), sl<TokenStore>()));
  sl.registerLazySingleton<ApiTransport>(() => ApiTransport(
        sl<http.Client>(),
        sl<TokenStore>(),
        refresher: sl<SessionRefresher>(),
      ));
  sl.registerLazySingleton<MultipartTransport>(() => MultipartTransport(
        sl<http.Client>(),
        sl<TokenStore>(),
        refresher: sl<SessionRefresher>(),
      ));

  // ── Feature AI (issue #237) ───────────────────────────────────
  sl.registerLazySingleton<AiRemoteDataSource>(
      () => HttpAiRemoteDataSource(sl<ApiTransport>()));
  sl.registerLazySingleton<AiRepository>(
      () => HttpAiRepository(sl<AiRemoteDataSource>()));

  // ── Services ──────────────────────────────────────────────────
  sl.registerLazySingleton<IApiClient>(() => ApiService());
  sl.registerLazySingleton<AiCvService>(
      () => AiCvService(sl<AiRemoteDataSource>()));
  sl.registerLazySingleton<PdfService>(() => PdfService(sl<IApiClient>()));
  // Exports CV typés + controller detail (issue #247).
  sl.registerFactory(() => ExportCvPdfUseCase(sl<PdfService>()));
  sl.registerFactory(() => ExportCvDocxUseCase(sl<PdfService>()));
  sl.registerFactory(() => CvDetailController(
        exportPdf: sl<ExportCvPdfUseCase>(),
        exportDocx: sl<ExportCvDocxUseCase>(),
      ));
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
  sl.registerLazySingleton<CvTrashRepository>(() => CvTrashRepository(api: sl()));
  sl.registerLazySingleton<ProfilePhotoRepository>(
    () => HttpProfilePhotoRepository(
      sl<IApiClient>(),
      // Base des medias = URL de l'API sans le suffixe /api (issue #242).
      mediaBaseUrl: ApiConstants.baseUrl.replaceAll('/api', ''),
    ),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => HttpAccountRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<NotificationSettingsRepository>(
    () => HttpNotificationSettingsRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<PublicPortfolioRepository>(
    () => HttpPublicPortfolioRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<CvShareRepository>(
    () => HttpCvShareRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<SecurePhotoRepository>(
    () => HttpSecurePhotoRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<PasswordResetRepository>(
    () => HttpPasswordResetRepository(sl<ApiTransport>()),
  );

  // ── Use Cases: Auth ───────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => UpdateProfileUseCase(sl<AuthRepository>()));

  // ── Use Cases: Account (issue #250) ──────────────────────────
  sl.registerFactory(() => ExportAccountDataUseCase(sl<AccountRepository>()));
  sl.registerFactory(() => DeleteAccountUseCase(sl<AccountRepository>()));

  // ── Use Cases: Reinitialisation mot de passe (issue #381) ────
  sl.registerFactory(
      () => RequestPasswordResetUseCase(sl<PasswordResetRepository>()));
  sl.registerFactory(
      () => ConfirmPasswordResetUseCase(sl<PasswordResetRepository>()));

  // ── Use Cases: CV ─────────────────────────────────────────────
  sl.registerFactory(() => GetAllCvsUseCase(sl<CvRepository>()));
  sl.registerFactory(() => GetCvByIdUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => UpdateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DeleteCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DuplicateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateVariantUseCase(sl<CvRepository>()));
  sl.registerFactory(
      () => UploadProfilePhotoUseCase(sl<ProfilePhotoRepository>()));

  // ── Use Cases: AI (issue #237 — port AiRepository, plus IApiClient) ──
  sl.registerFactory(() => EnhanceCvUseCase(sl<AiRepository>()));
  sl.registerFactory(() => MatchJobUseCase(sl<AiRepository>()));
  sl.registerFactory(() => GenerateResumeUseCase(sl<AiRepository>()));
  sl.registerFactory(() => SuggestBulletsUseCase(sl<AiRepository>()));
  sl.registerFactory(() => GenerateApplicationMessagesUseCase(sl<AiRepository>()));
  sl.registerLazySingleton<ClipboardCopier>(() => const SystemClipboardCopier());
  sl.registerFactory(() => GetAiStatusUseCase(sl<AiRepository>()));

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
  sl.registerLazySingleton<CvStore>(() => CvStore());
  sl.registerLazySingleton<CvWizardDraftStore>(() => CvWizardDraftStore());
  sl.registerLazySingleton<CvListController>(
      () => CvListController(
            getAllCvs: sl<GetAllCvsUseCase>(),
            store: sl<CvStore>(),
          ));
  sl.registerLazySingleton<CvEditorController>(
      () => CvEditorController(
            createCv: sl<CreateCvUseCase>(),
            updateCv: sl<UpdateCvUseCase>(),
            deleteCv: sl<DeleteCvUseCase>(),
            duplicateCv: sl<DuplicateCvUseCase>(),
            createVariant: sl<CreateVariantUseCase>(),
            repository: sl<CvRepository>(),
            store: sl<CvStore>(),
          ));
  sl.registerLazySingleton<cvp.CvDetailController>(
      () => cvp.CvDetailController(
            getCvById: sl<GetCvByIdUseCase>(),
            store: sl<CvStore>(),
          ));
  sl.registerLazySingleton<cvp.CvStyleController>(
      () => cvp.CvStyleController(
            repository: sl<CvRepository>(),
            store: sl<CvStore>(),
          ));
  sl.registerLazySingleton<OfflineCvSyncCoordinator>(
      () => OfflineCvSyncCoordinator(
            createCv: sl<CreateCvUseCase>(),
            updateCv: sl<UpdateCvUseCase>(),
            deleteCv: sl<DeleteCvUseCase>(),
            queue: sl<SyncQueue>(),
            store: sl<CvStore>(),
          ));
  sl.registerLazySingleton<CvConnectivitySyncController>(
      () => CvConnectivitySyncController(
            connectivity: sl<ConnectivityService>(),
            store: sl<CvStore>(),
            list: sl<CvListController>(),
            syncCoordinator: sl<OfflineCvSyncCoordinator>(),
          ));
  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
  sl.registerFactory<AiStatusProvider>(
      () => AiStatusProvider(getAiStatus: sl<GetAiStatusUseCase>()));
  sl.registerFactory<NotificationProvider>(
      () => NotificationProvider(sl<NotificationSettingsRepository>()));
  // Candidatures (issue #246) : Clean Architecture, remplace
  // JobApplicationProvider (transport direct + etat mutable).
  sl.registerLazySingleton<ExternalLinkLauncher>(
      () => const UrlLauncherLinkLauncher());
  sl.registerFactory<ApplicationRemoteDataSource>(
      () => HttpApplicationRemoteDataSource(sl<ApiTransport>()));
  sl.registerFactory<ApplicationRepository>(
      () => ApplicationRepositoryImpl(sl<ApplicationRemoteDataSource>()));
  sl.registerFactory<ApplicationListController>(
      () => ApplicationListController(
            listApplications:
                ListApplicationsUseCase(sl<ApplicationRepository>()),
            saveApplication:
                SaveApplicationUseCase(sl<ApplicationRepository>()),
            deleteApplication:
                DeleteApplicationUseCase(sl<ApplicationRepository>()),
          ));
}
