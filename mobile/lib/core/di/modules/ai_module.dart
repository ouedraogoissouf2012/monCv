// Cable la facade AiCvService @Deprecated (transitoire, retiree par #245).
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:get_it/get_it.dart';

import '../../../features/ai/application/enhance_cv_usecase.dart';
import '../../../features/ai/application/generate_application_messages_usecase.dart';
import '../../../features/ai/application/generate_resume_usecase.dart';
import '../../../features/ai/application/get_ai_status_usecase.dart';
import '../../../features/ai/application/match_job_usecase.dart';
import '../../../features/ai/application/suggest_bullets_usecase.dart';
import '../../../features/ai/compat/ai_service_facade.dart';
import '../../../features/ai/data/ai_remote_data_source.dart';
import '../../../features/ai/data/ai_repository_impl.dart';
import '../../../features/ai/domain/repositories/ai_repository.dart';
import '../../../providers/ai_status_provider.dart';
import '../../network/api_transport.dart';

/// Fonctionnalites IA : transport dedie, port [AiRepository] et use cases
/// (amelioration, correspondance d'offre, resume, suggestions, messages de
/// candidature, statut du sous-systeme).
///
/// Depuis l'issue #237, tout passe par [AiRepository] et non plus par
/// `IApiClient`.
void registerAiModule(GetIt sl) {
  sl.registerLazySingleton<AiRemoteDataSource>(
      () => HttpAiRemoteDataSource(sl<ApiTransport>()));
  sl.registerLazySingleton<AiRepository>(
      () => HttpAiRepository(sl<AiRemoteDataSource>()));
  sl.registerLazySingleton<AiCvService>(
      () => AiCvService(sl<AiRemoteDataSource>()));

  sl.registerFactory(() => EnhanceCvUseCase(sl<AiRepository>()));
  sl.registerFactory(() => MatchJobUseCase(sl<AiRepository>()));
  sl.registerFactory(() => GenerateResumeUseCase(sl<AiRepository>()));
  sl.registerFactory(() => SuggestBulletsUseCase(sl<AiRepository>()));
  sl.registerFactory(
      () => GenerateApplicationMessagesUseCase(sl<AiRepository>()));
  sl.registerFactory(() => GetAiStatusUseCase(sl<AiRepository>()));

  sl.registerFactory<AiStatusProvider>(
      () => AiStatusProvider(getAiStatus: sl<GetAiStatusUseCase>()));
}
