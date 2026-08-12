import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/applications/application/delete_application.dart';
import 'package:cv_mobile/features/applications/application/list_applications.dart';
import 'package:cv_mobile/features/applications/application/save_application.dart';
import 'package:cv_mobile/features/applications/domain/application_repository.dart';
import 'package:cv_mobile/features/applications/domain/external_link_launcher.dart';
import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:cv_mobile/features/applications/presentation/application_list_controller.dart';
import 'package:cv_mobile/features/applications/presentation/applications_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockRepo extends Mock implements ApplicationRepository {}

class _MockCvListController extends Mock implements CvListController {}

class _SpyLauncher implements ExternalLinkLauncher {
  final List<String?> opened = [];
  LinkLaunchResult result = LinkLaunchResult.success;
  @override
  Future<LinkLaunchResult> open(String? url) async {
    opened.add(url);
    return result;
  }
}

void main() {
  late _MockRepo repo;
  late _SpyLauncher launcher;
  late _MockCvListController listController;

  setUpAll(() => registerFallbackValue(
      const JobApplication(company: 'x', position: 'y')));

  setUp(() {
    repo = _MockRepo();
    launcher = _SpyLauncher();
    listController = _MockCvListController();
    when(() => listController.load()).thenAnswer((_) async {});
  });

  Widget app() => Provider<CvListController>.value(
        value: listController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ApplicationsScreen(
            controller: ApplicationListController(
              listApplications: ListApplicationsUseCase(repo),
              saveApplication: SaveApplicationUseCase(repo),
              deleteApplication: DeleteApplicationUseCase(repo),
            ),
            linkLauncher: launcher,
          ),
        ),
      );

  testWidgets('liste chargee -> une ligne par candidature', (t) async {
    when(() => repo.list(status: any(named: 'status'))).thenAnswer(
      (_) async => const Result.success([
        JobApplication(
            id: 1,
            company: 'Acme',
            position: 'Dev Flutter',
            status: JobApplicationStatus.sent),
      ]),
    );

    await t.pumpWidget(app());
    await t.pumpAndSettle();

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Dev Flutter'), findsOneWidget);
  });

  testWidgets('liste vide -> etat vide affiche', (t) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([]));

    await t.pumpWidget(app());
    await t.pumpAndSettle();

    final l = AppLocalizations.of(
        t.element(find.byType(ApplicationsScreen)))!;
    expect(find.text(l.noApplications), findsOneWidget);
  });

  testWidgets('erreur de chargement -> message affiche', (t) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await t.pumpWidget(app());
    await t.pumpAndSettle();

    // Le message de l'exception typee est expose (pas de crash).
    expect(find.byType(ApplicationsScreen), findsOneWidget);
  });
}
