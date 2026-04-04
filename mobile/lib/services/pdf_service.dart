import 'package:flutter/foundation.dart';
import '../models/cv.dart';
import '../utils/cv_pdf_generator.dart';
import '../utils/pdf_saver.dart';

/// Service encapsulant la generation et le telechargement de PDF.
class PdfService {
  static final PdfService _instance = PdfService._();
  PdfService._();
  factory PdfService() => _instance;

  /// Genere le PDF et le telecharge.
  /// Utilise compute() pour ne pas bloquer le main thread (sauf web).
  Future<void> downloadPdf(Cv cv) async {
    final bytes = await generate(cv);
    await savePdfBytes(bytes, 'cv-${cv.id ?? 'draft'}.pdf');
  }

  /// Genere le PDF en bytes.
  Future<Uint8List> generate(Cv cv) async {
    // Sur web, compute() ne fonctionne pas bien (pas de vrai isolate)
    // Sur mobile, on utilise compute() pour liberer le main thread
    if (kIsWeb) {
      return generateCvPdf(cv);
    }
    return compute(_generateInIsolate, cv);
  }
}

/// Fonction top-level pour compute() (doit etre top-level ou static)
Future<Uint8List> _generateInIsolate(Cv cv) => generateCvPdf(cv);
