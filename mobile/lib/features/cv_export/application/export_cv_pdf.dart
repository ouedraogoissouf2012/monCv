import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../../../core/usecase/usecase.dart';
import '../../../models/cv.dart';
import '../../../services/pdf_service.dart';

/// Exporte un CV au format PDF et declenche son telechargement (issue #247).
///
/// Enveloppe [PdfService.downloadPdf] dans un [Result] : les erreurs d'I/O ou
/// de generation deviennent une [AppException] typee, jamais propagees brutes
/// (le monolithe faisait `catch (e)` + `e.toString()`).
class ExportCvPdfUseCase implements UseCase<void, Cv> {
  const ExportCvPdfUseCase(this._pdf);

  final PdfService _pdf;

  @override
  Future<Result<void>> call(Cv cv) => safeCall(() => _pdf.downloadPdf(cv));
}
