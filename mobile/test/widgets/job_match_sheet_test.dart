import 'package:cv_mobile/core/di/injection_container.dart';
import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/features/ai/application/get_ai_status_usecase.dart';
import 'package:cv_mobile/features/ai/application/match_job_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/providers/ai_status_provider.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/usecases/cv/create_variant_usecase.dart';
import 'package:cv_mobile/widgets/ai_button.dart';
import 'package:cv_mobile/widgets/job_match_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAiRepo extends Mock implements AiRepository {}

class _MockCvRepo extends Mock implements CvRepository {}

class _MockGetAiStatus extends Mock implements GetAiStatusUseCase {}

void main() {
  late _MockAiRepo aiRepo;
  late _MockCvRepo cvRepo;
  late _MockGetAiStatus getAiStatus;

  setUpAll(() => registerFallbackValue(const NoParams()));

  // La sheet (orchestrateur G4) resout ses use cases via le service locator.
  setUp(() {
    aiRepo = _MockAiRepo();
    cvRepo = _MockCvRepo();
    getAiStatus = _MockGetAiStatus();
    // refresh() du provider est declenche par onAiError : on stubbe un echec
    // (le provider le gere gracieusement en gardant le dernier status).
    when(() => getAiStatus(any()))
        .thenAnswer((_) async => const Result.failure(NetworkException()));
    sl.registerFactory<MatchJobUseCase>(() => MatchJobUseCase(aiRepo));
    sl.registerFactory<CreateVariantUseCase>(
        () => CreateVariantUseCase(cvRepo));
  });
  tearDown(() {
    sl.unregister<MatchJobUseCase>();
    sl.unregister<CreateVariantUseCase>();
  });

  Widget testApp() => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AiStatusProvider(getAiStatus: getAiStatus),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const Scaffold(body: JobMatchSheet(cvId: 42)),
        ),
      );

  const report = JobMatch(score: 82, aiGenerated: true);

  testWidgets('etat initial : formulaire de saisie, pas de score', (t) async {
    await t.pumpWidget(testApp());
    // Le champ de saisie est present, aucun score affiche.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('82%'), findsNothing);
  });

  testWidgets('analyse reussie -> score typé affiche via les composants',
      (t) async {
    when(() => aiRepo.matchJob(42, any()))
        .thenAnswer((_) async => const Result.success(report));
    await t.pumpWidget(testApp());

    // Consentement + offre valide (>= 20 caracteres) puis analyse.
    await t.tap(find.byType(Checkbox));
    await t.enterText(find.byType(TextFormField),
        'Une offre suffisamment longue pour lancer une analyse ATS.');
    await t.pump();
    final l = AppLocalizations.of(t.element(find.byType(JobMatchSheet)))!;
    await t.tap(find.byType(AiButton));
    await t.pumpAndSettle();

    // Le score typé remonte du controller jusqu'aux composants (JobScoreCard
    // + l'entree d'historique fraichement enregistree) : au moins une occurrence.
    expect(find.text('82%'), findsWidgets);
    // Le formulaire a cede la place a la vue resultats (bouton "autre offre").
    expect(find.text(l.analyzeAnotherOffer), findsOneWidget);
  });

  testWidgets('erreur IA -> message expose, pas de score', (t) async {
    when(() => aiRepo.matchJob(42, any())).thenAnswer((_) async =>
        const Result.failure(
            AiException(code: 'AI_PROVIDER_DOWN', message: 'IA indisponible')));
    await t.pumpWidget(testApp());

    await t.tap(find.byType(Checkbox));
    await t.enterText(find.byType(TextFormField),
        'Une offre suffisamment longue pour lancer une analyse ATS.');
    await t.pump();
    await t.tap(find.byType(AiButton));
    await t.pumpAndSettle();

    expect(find.text('IA indisponible'), findsOneWidget);
    expect(find.text('82%'), findsNothing);
  });
}
