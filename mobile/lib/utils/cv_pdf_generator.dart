import 'dart:typed_data';

import '../features/cv/presentation/cv_presentation_model.dart';
import '../pdf/pdf_renderer.dart';

export '../pdf/pdf_renderer.dart';

Future<Uint8List> generateCvPdf(Cv cv, {Uint8List? photoBytes}) =>
    PdfRenderer.generate(cv, photoBytes: photoBytes);
