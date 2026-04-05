import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/cv.dart';
import '../utils/cv_pdf_generator.dart';
import '../utils/pdf_saver.dart';
import 'api_service.dart';

/// Service encapsulant la generation et le telechargement de PDF et DOCX.
class PdfService {
  static final PdfService _instance = PdfService._();
  PdfService._();
  factory PdfService() => _instance;

  /// Genere le PDF et le telecharge.
  Future<void> downloadPdf(Cv cv) async {
    final bytes = await generate(cv);
    await savePdfBytes(bytes, 'cv-${cv.id ?? 'draft'}.pdf');
  }

  /// Telecharge le DOCX depuis le backend.
  Future<void> downloadDocx(int cvId) async {
    final bytes = await ApiService().downloadCvDocx(cvId);
    await savePdfBytes(Uint8List.fromList(bytes), 'cv-$cvId.docx');
  }

  /// Genere le PDF en bytes.
  Future<Uint8List> generate(Cv cv) async {
    if (kIsWeb) {
      return generateCvPdf(cv);
    }
    return compute(_generateInIsolate, cv);
  }
}

/// Fonction top-level pour compute()
Future<Uint8List> _generateInIsolate(Cv cv) => generateCvPdf(cv);
