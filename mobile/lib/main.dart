import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/di/injection_container.dart';
import 'providers/auth_provider.dart';
import 'providers/cv_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'MonCV',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppThemes.get(themeProvider.mode),
          );
        },
      ),
    );
  }
}
