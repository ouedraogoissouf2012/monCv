import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv_export/application/export_cv_docx.dart';
import 'package:cv_mobile/features/cv_export/application/export_cv_pdf.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPdfService extends Mock implements PdfService {}

void main() {
  late _MockPdfService pdf;

  final cv = Cv(id: 7, titre: 'Dev');

  setUpAll(() => registerFallbackValue(Cv(titre: 'x')));
  setUp(() => pdf = _MockPdfService());

  group('ExportCvPdfUseCase (#247 B1)', () {
    test('succes -> Result.success, delegue a downloadPdf', () async {
      when(() => pdf.downloadPdf(any())).thenAnswer((_) async {});

      final r = await ExportCvPdfUseCase(pdf).call(cv);

      expect(r, isA<Success<void>>());
      verify(() => pdf.downloadPdf(cv)).called(1);
    });

    test('exception d export -> Result.failure (pas de throw)', () async {
      when(() => pdf.downloadPdf(any())).thenThrow(Exception('disk full'));

      final r = await ExportCvPdfUseCase(pdf).call(cv);

      expect(r, isA<Failure<void>>());
    });
  });

  group('ExportCvDocxUseCase (#247 B1)', () {
    test('succes -> Result.success, delegue a downloadDocx(cvId)', () async {
      when(() => pdf.downloadDocx(7)).thenAnswer((_) async {});

      final r = await ExportCvDocxUseCase(pdf).call(7);

      expect(r, isA<Success<void>>());
      verify(() => pdf.downloadDocx(7)).called(1);
    });

    test('exception reseau -> Result.failure', () async {
      when(() => pdf.downloadDocx(any()))
          .thenThrow(const NetworkException());

      final r = await ExportCvDocxUseCase(pdf).call(7);

      expect(r, isA<Failure<void>>());
      expect((r as Failure).exception, isA<NetworkException>());
    });
  });
}
