import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/error/result.dart';
import 'features/cv_detail/presentation/cv_detail_controller.dart';
import 'features/cv_detail/presentation/cv_detail_screen.dart';
import 'features/cv_export/application/export_cv_pdf.dart';
import 'features/cv_list/application/import_cv.dart';
import 'features/cv_list/presentation/cv_list_screen.dart';
import 'features/cv_list/presentation/cv_trash_screen.dart';
import 'features/cv/presentation/controllers/cv_style_controller.dart' as cvp;
import 'features/cv_style/presentation/cv_style_controller.dart';
import 'features/cv_style/presentation/cv_style_editor_screen.dart';
import 'features/cv/presentation/cv_presentation_model.dart';
import 'providers/auth_provider.dart';
import 'services/i_api_client.dart';
import 'features/auth/presentation/login/login_screen.dart';
import 'features/auth/presentation/register/register_screen.dart';
import 'features/password_reset/application/confirm_password_reset.dart';
import 'features/password_reset/application/request_password_reset.dart';
import 'features/password_reset/presentation/forgot_password_screen.dart';
import 'features/password_reset/presentation/reset_password_screen.dart';
import 'screens/cv/cv_form_screen.dart';
import 'features/landing/presentation/landing_screen.dart';
import 'screens/privacy/privacy_screen.dart';
import 'screens/share/public_portfolio_screen.dart';
import 'core/di/injection_container.dart';
import 'features/account/application/delete_account.dart';
import 'features/account/application/export_account_data.dart';
import 'features/applications/domain/external_link_launcher.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/applications/presentation/application_list_controller.dart';
import 'features/applications/presentation/applications_screen.dart';

class AppRouter {
  @visibleForTesting
  static String? resolveAuthRedirect({
    required bool isCheckingAuth,
    required bool isAuthenticated,
    required String location,
    required bool isWeb,
  }) {
    if (isCheckingAuth) return null;

    final isPublicPortfolio = location.startsWith('/public/cv/');
    // Reinitialisation de mot de passe (issue #381) : accessible sans session
    // (l'utilisateur a justement perdu l'acces a son compte).
    final isPasswordReset = location == '/forgot-password' ||
        location.startsWith('/reset-password');
    final isPublic = location == '/login' ||
        location == '/register' ||
        location == '/privacy' ||
        location == '/landing' ||
        isPasswordReset ||
        isPublicPortfolio;

    if (!isAuthenticated && !isPublic) {
      return isWeb ? '/landing' : '/login';
    }
    if (isAuthenticated && isPublic && !isPublicPortfolio) return '/home';
    return null;
  }

  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/home',
      redirect: (context, state) {
        return resolveAuthRedirect(
          isCheckingAuth: authProvider.isCheckingAuth,
          isAuthenticated: authProvider.isAuthenticated,
          location: state.matchedLocation,
          isWeb: kIsWeb,
        );
      },
      routes: [
        GoRoute(
          path: '/landing',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => ForgotPasswordScreen(
            requestReset: sl<RequestPasswordResetUseCase>(),
          ),
        ),
        GoRoute(
          path: '/reset-password/:token',
          builder: (context, state) => ResetPasswordScreen(
            token: state.pathParameters['token']!,
            confirmReset: sl<ConfirmPasswordResetUseCase>(),
          ),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyScreen(),
        ),
        GoRoute(
          path: '/public/cv/:token',
          builder: (context, state) => PublicPortfolioScreen(
            token: state.pathParameters['token']!,
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              CvListScreen(importCv: ImportCvUseCase(sl<IApiClient>().importCv)),
        ),
        GoRoute(
          path: '/cvs/create',
          builder: (context, state) => const CvFormScreen(),
        ),
        GoRoute(
          path: '/cvs/trash',
          builder: (context, state) => const CvTrashScreen(),
        ),
        GoRoute(
          path: '/cvs/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CvDetailScreen(
              cvId: id,
              controller: sl<CvDetailController>(),
            );
          },
        ),
        GoRoute(
          path: '/cvs/:id/edit',
          builder: (context, state) {
            final cv = state.extra as Cv;
            return CvFormScreen(cv: cv);
          },
        ),
        GoRoute(
          path: '/cvs/:id/style',
          builder: (context, state) {
            final cv = state.extra as Cv;
            return CvStyleEditorScreen(
              cv: cv,
              exportPdf: sl<ExportCvPdfUseCase>(),
              controller: CvStyleController(
                initial: cv.style,
                // Adapte le save legacy (bool) vers Result typé.
                save: (style) async {
                  final ok = await sl<cvp.CvStyleController>().update(cv.id!, style);
                  return ok
                      ? const Result.success(null)
                      : const Result.failure(ServerException());
                },
              ),
            );
          },
        ),
        GoRoute(
            path: '/profile',
            builder: (context, state) => ProfileScreen(
                  exportData: sl<ExportAccountDataUseCase>(),
                  deleteAccount: sl<DeleteAccountUseCase>(),
                )),
        GoRoute(
            path: '/applications',
            builder: (context, state) => ApplicationsScreen(
                  controller: sl<ApplicationListController>(),
                  linkLauncher: sl<ExternalLinkLauncher>(),
                )),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Center(child: Text(state.error.toString())),
      ),
    );
  }
}
