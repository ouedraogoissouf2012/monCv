import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/cv_repository.dart';
import '../../repositories/cached_cv_repository.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
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

  // ── Providers ─────────────────────────────────────────────────
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(repository: sl<AuthRepository>()),
  );
  sl.registerFactory<CvProvider>(
    () => CvProvider(
      repository: sl<CvRepository>(),
      connectivity: sl<ConnectivityService>(),
    ),
  );
  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
}
