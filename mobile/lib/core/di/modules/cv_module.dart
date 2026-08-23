import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/cv/application/sync/offline_cv_sync_coordinator.dart';
import '../../../features/cv/application/upload_profile_photo_usecase.dart';
import '../../../features/cv/data/http_profile_photo_repository.dart';
import '../../../features/cv/domain/repositories/profile_photo_repository.dart';
import '../../../features/cv/presentation/controllers/cv_connectivity_sync_controller.dart';
import '../../../features/cv/presentation/controllers/cv_detail_controller.dart' as cvp;
import '../../../features/cv/presentation/controllers/cv_editor_controller.dart';
import '../../../features/cv/presentation/controllers/cv_list_controller.dart';
import '../../../features/cv/presentation/controllers/cv_style_controller.dart' as cvp;
import '../../../features/cv/presentation/cv_store.dart';
import '../../../features/cv/presentation/cv_writer.dart';
import '../../../features/cv_detail/presentation/cv_detail_controller.dart';
import '../../../features/cv_export/application/export_cv_docx.dart';
import '../../../features/cv_export/application/export_cv_pdf.dart';
import '../../../features/cv_share/data/http_cv_share_repository.dart';
import '../../../features/cv_share/domain/cv_share_repository.dart';
import '../../../features/media/data/http_secure_photo_repository.dart';
import '../../../features/media/domain/secure_photo_repository.dart';
import '../../../features/public_portfolio/data/http_public_portfolio_repository.dart';
import '../../../features/public_portfolio/domain/public_portfolio_repository.dart';
import '../../../repositories/cached_cv_repository.dart';
import '../../../repositories/cv_repository.dart';
import '../../../repositories/cv_trash_repository.dart';
import '../../../screens/cv/controllers/cv_wizard_draft_store.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/i_api_client.dart';
import '../../../services/pdf_service.dart';
import '../../../services/share_service.dart';
import '../../../services/sync_queue.dart';
import '../../../usecases/cv/create_cv_usecase.dart';
import '../../../usecases/cv/create_variant_usecase.dart';
import '../../../usecases/cv/delete_cv_usecase.dart';
import '../../../usecases/cv/duplicate_cv_usecase.dart';
import '../../../usecases/cv/get_all_cvs_usecase.dart';
import '../../../usecases/cv/get_cv_by_id_usecase.dart';
import '../../../usecases/cv/update_cv_usecase.dart';
import '../../../utils/constants.dart';

/// Coeur metier du produit : persistance des CV, use cases, etat partage,
/// controllers de presentation, exports et synchronisation hors ligne.
///
/// Deux `CvDetailController` distincts coexistent : celui de `cv_detail/`
/// pilote les exports, celui de `cv/presentation/` (alias `cvp`) pilote la
/// lecture du CV courant. Les alias sont conserves tels quels.
void registerCvModule(GetIt sl) {
  // ── Persistance ───────────────────────────────────────────────
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
  sl.registerLazySingleton<CvShareRepository>(
    () => HttpCvShareRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<SecurePhotoRepository>(
    () => HttpSecurePhotoRepository(sl<IApiClient>()),
  );
  sl.registerLazySingleton<PublicPortfolioRepository>(
    () => HttpPublicPortfolioRepository(sl<IApiClient>()),
  );

  // ── Services ──────────────────────────────────────────────────
  sl.registerLazySingleton<PdfService>(() => PdfService(sl<IApiClient>()));
  sl.registerLazySingleton<ShareService>(() => ShareService(sl<IApiClient>()));
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue(sl<SharedPreferences>()));

  // ── Exports CV typés + controller detail (issue #247) ─────────
  sl.registerFactory(() => ExportCvPdfUseCase(sl<PdfService>()));
  sl.registerFactory(() => ExportCvDocxUseCase(sl<PdfService>()));
  sl.registerFactory(() => CvDetailController(
        exportPdf: sl<ExportCvPdfUseCase>(),
        exportDocx: sl<ExportCvDocxUseCase>(),
      ));

  // ── Use cases ─────────────────────────────────────────────────
  sl.registerFactory(() => GetAllCvsUseCase(sl<CvRepository>()));
  sl.registerFactory(() => GetCvByIdUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => UpdateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DeleteCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => DuplicateCvUseCase(sl<CvRepository>()));
  sl.registerFactory(() => CreateVariantUseCase(sl<CvRepository>()));
  sl.registerFactory(
      () => UploadProfilePhotoUseCase(sl<ProfilePhotoRepository>()));

  // ── Etat partage et controllers ───────────────────────────────
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
  // Port d'ecriture CV (#501) : les consommateurs dependent de l'interface.
  sl.registerLazySingleton<CvWriter>(() => sl<CvEditorController>());
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

  // ── Synchronisation hors ligne ────────────────────────────────
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
}
