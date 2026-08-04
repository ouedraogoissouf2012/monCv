import 'package:cv_mobile/core/di/injection_container.dart';
import 'package:cv_mobile/features/ai/application/enhance_cv_usecase.dart';
import 'package:cv_mobile/features/ai/application/get_ai_status_usecase.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/widgets/ai_enhance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/providers/ai_status_provider.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

class _MockGetAiStatus extends Mock implements GetAiStatusUseCase {}

void main() {
  final cv = Cv(id: 42, titre: 'Community manager');

  // Le sheet resout EnhanceCvUseCase via le service locator (voie typee #244).
  setUpAll(() {
    if (!sl.isRegistered<EnhanceCvUseCase>()) {
      sl.registerFactory(() => EnhanceCvUseCase(_MockAiRepo()));
    }
  });
  tearDownAll(() {
    if (sl.isRegistered<EnhanceCvUseCase>()) {
      sl.unregister<EnhanceCvUseCase>();
    }
  });

  Widget testApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AiStatusProvider(getAiStatus: _MockGetAiStatus()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('le mode relecture affiche une action orthographique dédiée',
      (tester) async {
    await tester.pumpWidget(
      testApp(AiEnhanceSheet(cv: cv, proofreadOnly: true)),
    );

    expect(find.text('Correction orthographique'), findsOneWidget);
    expect(find.text('Relire le CV'), findsOneWidget);
    expect(
      find.textContaining('J\'accepte que le contenu de ce CV'),
      findsOneWidget,
    );
    // Mode relecture : pas de selecteur de niveaux.
    expect(find.text('Medium'), findsNothing);
    expect(find.text('Max'), findsNothing);
    expect(find.byIcon(Icons.spellcheck_rounded), findsWidgets);
  });

  testWidgets('le mode amélioration conserve les trois niveaux',
      (tester) async {
    await tester.pumpWidget(testApp(AiEnhanceSheet(cv: cv)));

    expect(find.text('Lite'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(
      find.textContaining('J\'accepte que le contenu de ce CV'),
      findsOneWidget,
    );
  });
}
