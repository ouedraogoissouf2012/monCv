import 'package:cv_mobile/features/cv/application/upload_profile_photo_usecase.dart';
import 'package:cv_mobile/features/cv/domain/repositories/profile_photo_repository.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/personal_info_form_controller.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/photo/profile_photo_field.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/screens/cv/widgets/editable_profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfilePhotoRepository {}

void main() {
  late PersonalInfoFormController controller;
  late UploadProfilePhotoUseCase useCase;

  setUp(() {
    // Sans URL : evite le SecurePhoto interne (qui exige un Provider<IApiClient>
    // du transport, indisponible en test unitaire). Le chemin d'upload complet
    // est couvert par les tests du use case (D4).
    controller = PersonalInfoFormController.fromPersonalInfo(null);
    useCase = UploadProfilePhotoUseCase(_MockRepo());
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
        body: ProfilePhotoField(
          controller: controller,
          uploadPhoto: useCase,
          onChanged: () {},
        ),
      ),
    ));
  }

  testWidgets('affiche EditableProfilePhoto avec l URL du controller (#242 D5)',
      (tester) async {
    await pump(tester);

    final photo = tester
        .widget<EditableProfilePhoto>(find.byType(EditableProfilePhoto));
    expect(photo.url, isNull);
    expect(photo.loading, isFalse);
  });

  testWidgets('libelle "photo de profil optionnel" present (#242 D5)',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('optionnel'), findsOneWidget);
  });
}
