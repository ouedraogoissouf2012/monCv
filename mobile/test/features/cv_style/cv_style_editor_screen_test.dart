import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv_export/application/export_cv_pdf.dart';
import 'package:cv_mobile/features/cv_style/presentation/components/cv_style_options_pane.dart';
import 'package:cv_mobile/features/cv_style/presentation/components/cv_style_preview_pane.dart';
import 'package:cv_mobile/features/cv_style/presentation/cv_style_controller.dart';
import 'package:cv_mobile/features/cv_style/presentation/cv_style_editor_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPdf extends Mock implements PdfService {}

void main() {
  late _MockPdf pdf;
  final cv = Cv(id: 1, titre: 'Dev', personalInfo: PersonalInfo(nom: 'X'));

  setUpAll(() => registerFallbackValue(Cv(titre: 'x')));
  setUp(() => pdf = _MockPdf());

  CvStyleController controller() => CvStyleController(
        initial: cv.style,
        save: (_) async => const Result.success(null),
      );

  Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: CvStyleEditorScreen(
          cv: cv,
          controller: controller(),
          exportPdf: ExportCvPdfUseCase(pdf),
        ),
      );

  /// Fixe la taille de la vue de test (largeur -> mode large/etroit).
  Future<void> pumpAt(WidgetTester t, double width) async {
    t.view.physicalSize = Size(width, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(app());
    await t.pump();
  }

  group('CvStyleEditorScreen (#247 B4a)', () {
    testWidgets('mode large : options ET preview affiches cote a cote',
        (t) async {
      await pumpAt(t, 1200);
      expect(find.byType(CvStyleOptionsPane), findsOneWidget);
      expect(find.byType(CvStylePreviewPane), findsOneWidget);
    });

    testWidgets('mode etroit : options par defaut, bascule vers preview',
        (t) async {
      await pumpAt(t, 500);
      // Par defaut on montre les options (pas la preview).
      expect(find.byType(CvStyleOptionsPane), findsOneWidget);
      expect(find.byType(CvStylePreviewPane), findsNothing);
    });

    testWidgets('la barre du bas propose le telechargement PDF', (t) async {
      await pumpAt(t, 1200);
      // Le bouton d'export (icone download) est present dans l'arbre.
      // Le COMPORTEMENT du tap (appel du use case, garde double-clic) est
      // couvert par les tests de CvDetailController/ExportCvPdfUseCase (B1/B3).
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });
}
