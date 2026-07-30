import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/generate_resume_usecase.dart';
import 'package:cv_mobile/features/cv/domain/policies/cv_validation_thresholds.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/ai_resume_field.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/personal_info_form_controller.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenerateResume extends Mock implements GenerateResumeUseCase {}

class _FakeParams extends Fake implements GenerateResumeParams {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeParams()));

  late _MockGenerateResume useCase;
  late PersonalInfoFormController controller;

  setUp(() {
    useCase = _MockGenerateResume();
    controller = PersonalInfoFormController.fromPersonalInfo(null);
  });
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: AiResumeField(
            controller: controller,
            generateResume: useCase,
            onChanged: () {},
          ),
        ),
      ),
    ));
  }

  testWidgets('sans consentement -> bouton generer desactive (#242 D5)',
      (tester) async {
    await pump(tester);
    final button = tester
        .widget<TextButton>(find.byKey(const Key('ai-generate-button')));
    expect(button.onPressed, isNull);
  });

  testWidgets('consentement + succes -> resume rempli via le use case',
      (tester) async {
    when(() => useCase(any()))
        .thenAnswer((_) async => const Result.success('Resume genere par IA'));

    await pump(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-generate-button')));
    await tester.pumpAndSettle();

    expect(controller.resume.text, 'Resume genere par IA');
    verify(() => useCase(any())).called(1);
  });

  testWidgets('echec du use case -> message neutre, pas de fuite fournisseur',
      (tester) async {
    when(() => useCase(any()))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await pump(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-generate-button')));
    await tester.pumpAndSettle();

    // Le resume reste vide, une snackbar neutre s'affiche (aucun "deepseek").
    expect(controller.resume.text, isEmpty);
    expect(find.textContaining('deepseek', findRichText: true), findsNothing);
  });

  testWidgets('indicateur "trop court" fonde sur le seuil centralise (#242 D5)',
      (tester) async {
    await pump(tester);

    // Saisir un texte plus court que le seuil.
    final short = 'x' * (CvValidationThresholds.minSummaryLength - 1);
    await tester.enterText(find.byType(TextFormField), short);
    await tester.pumpAndSettle();

    expect(find.textContaining('trop court'), findsOneWidget);
  });
}
