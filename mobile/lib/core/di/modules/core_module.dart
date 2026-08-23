import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/application_messages/data/system_clipboard_copier.dart';
import '../../../features/application_messages/domain/clipboard_copier.dart';
import '../../../features/applications/data/url_launcher_link_launcher.dart';
import '../../../features/applications/domain/external_link_launcher.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/i_api_client.dart';
import '../../network/api_transport.dart';
import '../../network/multipart_transport.dart';
import '../../network/session_refresher.dart';
import '../../network/token_store.dart';

/// Socle technique partage par toutes les fonctionnalites : stockage local,
/// transport reseau, connectivite et ports d'infrastructure generiques
/// (presse-papier, ouverture de liens externes).
///
/// Seule fonction d'enregistrement asynchrone : [SharedPreferences] doit etre
/// resolu avant d'etre place dans le conteneur. Tous les autres modules sont
/// synchrones, leurs dependances etant paresseuses.
Future<void> registerCoreModule(GetIt sl) async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

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
  sl.registerLazySingleton<IApiClient>(() => ApiService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // Ports d'infrastructure generiques, consommes par plusieurs features.
  sl.registerLazySingleton<ClipboardCopier>(() => const SystemClipboardCopier());
  sl.registerLazySingleton<ExternalLinkLauncher>(
      () => const UrlLauncherLinkLauncher());

  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
}
