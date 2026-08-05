import 'dart:async';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv_detail/presentation/cv_detail_controller.dart';
import 'package:cv_mobile/features/cv_export/application/export_cv_docx.dart';
import 'package:cv_mobile/features/cv_export/application/export_cv_pdf.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPdf extends Mock implements PdfService {}

void main() {
  late _MockPdf pdf;
  final cv = Cv(id: 7, titre: 'Dev');

  setUpAll(() => registerFallbackValue(Cv(titre: 'x')));
  setUp(() => pdf = _MockPdf());

  CvDetailController controller() => CvDetailController(
        exportPdf: ExportCvPdfUseCase(pdf),
        exportDocx: ExportCvDocxUseCase(pdf),
      );

  group('export PDF (#247 B3)', () {
    test('succes -> ExportOutcome.success, pas d erreur', () async {
      when(() => pdf.downloadPdf(any())).thenAnswer((_) async {});
      final c = controller();

      final outcome = await c.exportPdf(cv);

      expect(outcome, ExportOutcome.success);
      expect(c.lastError, isNull);
      expect(c.exportingPdf, isFalse);
    });

    test('echec -> ExportOutcome.failure + erreur TYPEE exposee', () async {
      when(() => pdf.downloadPdf(any())).thenThrow(const NetworkException());
      final c = controller();

      final outcome = await c.exportPdf(cv);

      expect(outcome, ExportOutcome.failure);
      expect(c.lastError, isA<NetworkException>());
    });

    test('double tap : 2e export ignore pendant le 1er (anti double-clic)',
        () async {
      final gate = Completer<void>();
      when(() => pdf.downloadPdf(any())).thenAnswer((_) => gate.future);
      final c = controller();

      final first = c.exportPdf(cv); // demarre, reste en cours
      expect(c.exportingPdf, isTrue);
      final second = await c.exportPdf(cv); // doit etre ignore

      expect(second, ExportOutcome.failure, reason: 'refuse pendant le 1er');
      gate.complete();
      expect(await first, ExportOutcome.success);
      // Un seul appel reel malgre deux taps.
      verify(() => pdf.downloadPdf(any())).called(1);
    });
  });

  group('export DOCX (#247 B3)', () {
    test('succes -> success + delegue a downloadDocx(cvId)', () async {
      when(() => pdf.downloadDocx(7)).thenAnswer((_) async {});
      final c = controller();

      final outcome = await c.exportDocx(7);

      expect(outcome, ExportOutcome.success);
      verify(() => pdf.downloadDocx(7)).called(1);
    });

    test('PDF et DOCX ont des gardes independants', () async {
      final pdfGate = Completer<void>();
      when(() => pdf.downloadPdf(any())).thenAnswer((_) => pdfGate.future);
      when(() => pdf.downloadDocx(any())).thenAnswer((_) async {});
      final c = controller();

      final pdfFuture = c.exportPdf(cv); // PDF en cours
      // DOCX doit rester possible pendant un export PDF.
      final docx = await c.exportDocx(7);

      expect(docx, ExportOutcome.success);
      pdfGate.complete();
      await pdfFuture;
    });
  });
}
