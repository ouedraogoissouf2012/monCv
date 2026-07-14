import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/di/injection_container.dart';
import 'l10n/app_localizations.dart';
import 'providers/ai_status_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cv_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/job_application_provider.dart';
import 'services/push_notification_service.dart';
import 'router.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase reste optionnel en local tant que flutterfire configure n'a pas ete execute.
    }
  }
  await initDependencies();
  if (!MonitoringConstants.sentryEnabled) {
    runApp(const MyApp());
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = MonitoringConstants.sentryDsn;
      options.environment = AppEnvironment.value;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;
  bool _pushInitialized = false;

  @override
  void initState() {
    super.initState();
    _authProvider = sl<AuthProvider>();
    _router = AppRouter.create(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => sl<CvProvider>()),
        ChangeNotifierProvider(create: (_) => sl<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AiStatusProvider()..refresh()),
        ChangeNotifierProvider(create: (_) => sl<NotificationProvider>()),
        ChangeNotifierProvider(create: (_) => sl<JobApplicationProvider>()),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, AuthProvider>(
        builder: (context, themeProvider, localeProvider, authProvider, _) {
          if (authProvider.isAuthenticated && !_pushInitialized) {
            _pushInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              sl<PushNotificationService>().initialize(_router);
              context.read<NotificationProvider>().load();
            });
          } else if (!authProvider.isAuthenticated && _pushInitialized) {
            _pushInitialized = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              sl<PushNotificationService>().deactivate();
            });
          }
          return MaterialApp.router(
            title: 'MonCV',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppThemes.get(themeProvider.mode),
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
