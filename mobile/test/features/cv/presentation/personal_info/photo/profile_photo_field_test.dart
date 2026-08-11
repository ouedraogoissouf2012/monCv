import 'dart:async';
import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/application/upload_profile_photo_usecase.dart';
import 'package:cv_mobile/features/cv/domain/repositories/profile_photo_repository.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/personal_info_form_controller.dart';
import 'package:cv_mobile/features/cv/presentation/personal_info/photo/profile_photo_field.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/screens/cv/widgets/editable_profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfilePhotoRepository {}

class _MockPicker extends Mock implements ImagePicker {}

void main() {
  late PersonalInfoFormController controller;
  late UploadProfilePhotoUseCase useCase;

  setUpAll(() => registerFallbackValue(ImageSource.gallery));

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

  testWidgets(
      'le bouton reste desactive pendant l upload (pas de double upload)',
      (tester) async {
    final picker = _MockPicker();
    final repo = _MockRepo();
    final uploadCompleter = Completer<Result<String>>();
    // PNG 1x1 valide : EditableProfilePhoto affiche l'apercu (MemoryImage), donc
    // les octets doivent etre decodables par le codec image.
    final fakeFile = XFile.fromData(
      Uint8List.fromList(const <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
        0x42, 0x60, 0x82,
      ]),
      name: 'p.png',
      mimeType: 'image/png',
    );
    when(() => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        )).thenAnswer((_) async => fakeFile);
    when(() => repo.uploadFile(any()))
        .thenAnswer((_) => uploadCompleter.future);

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
          uploadPhoto: UploadProfilePhotoUseCase(repo),
          onChanged: () {},
          picker: picker,
        ),
      ),
    ));

    // Selection via la galerie (feuille modale mobile).
    await tester.tap(find.byType(EditableProfilePhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    // Laisse la chaine async atteindre l'upload en vol (completer non complete).
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    // Pendant l'upload : verrou actif -> bouton desactive (onTap null).
    var photo =
        tester.widget<EditableProfilePhoto>(find.byType(EditableProfilePhoto));
    expect(photo.loading, isTrue);
    expect(photo.onTap, isNull);

    // Fin de l'upload : verrou relache.
    uploadCompleter.complete(const Result.success('https://x/p.jpg'));
    await tester.pumpAndSettle();
    photo =
        tester.widget<EditableProfilePhoto>(find.byType(EditableProfilePhoto));
    expect(photo.loading, isFalse);
    verify(() => repo.uploadFile(any())).called(1);
  });
}
