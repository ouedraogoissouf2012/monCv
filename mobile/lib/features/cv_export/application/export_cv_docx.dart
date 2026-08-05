import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../../../core/usecase/usecase.dart';
import '../../../services/pdf_service.dart';

/// Exporte un CV au format DOCX (via le backend) et declenche son
/// telechargement (issue #247).
///
/// Enveloppe [PdfService.downloadDocx] dans un [Result] : les erreurs reseau/
/// I/O deviennent une [AppException] typee, jamais propagees brutes.
class ExportCvDocxUseCase implements UseCase<void, int> {
  const ExportCvDocxUseCase(this._pdf);

  final PdfService _pdf;

  @override
  Future<Result<void>> call(int cvId) => safeCall(() => _pdf.downloadDocx(cvId));
}
