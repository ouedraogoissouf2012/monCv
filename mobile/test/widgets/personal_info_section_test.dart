import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/generate_resume_usecase.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/cv/application/upload_profile_photo_usecase.dart';
import 'package:cv_mobile/features/cv/domain/repositories/profile_photo_repository.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/personal_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockPhotoRepo extends Mock implements ProfilePhotoRepository {}

class _MockAiRepo extends Mock implements AiRepository {}

// Use cases reels branches sur des repos mockes : la section se monte sans
// initialiser le service locator (l'orchestrateur accepte les use cases en
// parametre, cf. #242 D5b).
UploadProfilePhotoUseCase _uploadUseCase() =>
    UploadProfilePhotoUseCase(_MockPhotoRepo());

GenerateResumeUseCase _resumeUseCase() {
  final repo = _MockAiRepo();
  when(() => repo.generateResume(any(), any(), any()))
      .thenAnswer((_) async => const Result.success(''));
  return GenerateResumeUseCase(repo);
}

Widget _wrap(PersonalInfoSection section) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: SingleChildScrollView(child: section),
      ),
    );

void main() {
  testWidgets('la ville propose Abidjan selon le pays', (tester) async {
    PersonalInfo? latest;
    await tester.pumpWidget(_wrap(PersonalInfoSection(
      personalInfo: PersonalInfo(pays: "Côte d'Ivoire"),
      onChanged: (value) => latest = value,
      uploadPhoto: _uploadUseCase(),
      generateResume: _resumeUseCase(),
    )));

    await tester.enterText(find.byKey(const Key('city-field')), 'abi');
    await tester.pumpAndSettle();

    expect(find.text('Abidjan'), findsOneWidget);
    await tester.tap(find.text('Abidjan'));
    await tester.pumpAndSettle();

    expect(latest?.ville, 'Abidjan');
  });

  testWidgets('la ville reste libre pour un pays non couvert', (tester) async {
    PersonalInfo? latest;
    await tester.pumpWidget(_wrap(PersonalInfoSection(
      personalInfo: PersonalInfo(pays: 'Japon'),
      onChanged: (value) => latest = value,
      uploadPhoto: _uploadUseCase(),
      generateResume: _resumeUseCase(),
    )));

    await tester.enterText(find.byKey(const Key('city-field')), 'Tokyo');
    await tester.pump();

    expect(latest?.ville, 'Tokyo');
  });
}
