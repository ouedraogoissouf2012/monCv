import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../models/cv.dart';
import '../../cv_export/application/export_cv_docx.dart';
import '../../cv_export/application/export_cv_pdf.dart';

/// Resultat d'une action d'export, expose a la vue (issue #247, B3).
enum ExportOutcome { success, failure }

/// Orchestre les actions d'export d'un CV (issue #247, B3).
///
/// Extrait la logique de `_downloadPdf`/`_downloadDocx` du monolithe
/// (cv_detail_screen.dart:37-91) : garde anti double-clic (une seule commande
/// a la fois), erreurs TYPEES via Result (fin de `catch (e)` + `e.toString()`).
/// Les effets UI (SnackBar) restent a la vue, declenches selon [ExportOutcome].
class CvDetailController extends ChangeNotifier {
  CvDetailController({
    required ExportCvPdfUseCase exportPdf,
    required ExportCvDocxUseCase exportDocx,
  })  : _exportPdf = exportPdf,
        _exportDocx = exportDocx;

  final ExportCvPdfUseCase _exportPdf;
  final ExportCvDocxUseCase _exportDocx;

  bool _exportingPdf = false;
  bool _exportingDocx = false;
  AppException? _lastError;

  bool get exportingPdf => _exportingPdf;
  bool get exportingDocx => _exportingDocx;

  /// Derniere erreur d'export typee (pour un message localise cote vue).
  AppException? get lastError => _lastError;

  /// Exporte le CV en PDF. Le garde anti double-clic empeche deux exports PDF
  /// simultanes (crit. #247 : double tap export). Sans effet si deja en cours.
  Future<ExportOutcome> exportPdf(Cv cv) =>
      _run(() => _exportPdf(cv), isPdf: true);

  /// Exporte le CV en DOCX. Meme garde anti double-clic.
  Future<ExportOutcome> exportDocx(int cvId) =>
      _run(() => _exportDocx(cvId), isPdf: false);

  Future<ExportOutcome> _run(
    Future<Result<void>> Function() action, {
    required bool isPdf,
  }) async {
    if (isPdf ? _exportingPdf : _exportingDocx) return ExportOutcome.failure;
    _setBusy(isPdf, true);
    _lastError = null;

    final result = await action();
    _setBusy(isPdf, false);

    switch (result) {
      case Success():
        return ExportOutcome.success;
      case Failure(:final exception):
        _lastError = exception;
        notifyListeners();
        return ExportOutcome.failure;
    }
  }

  void _setBusy(bool isPdf, bool busy) {
    if (isPdf) {
      _exportingPdf = busy;
    } else {
      _exportingDocx = busy;
    }
    notifyListeners();
  }
}
