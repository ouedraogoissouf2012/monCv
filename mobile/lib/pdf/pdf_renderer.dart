import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv.dart';
import '../utils/cv_levels.dart';

part 'sections/certifications_section.dart';
part 'sections/education_section.dart';
part 'sections/experience_section.dart';
part 'sections/header_section.dart';
part 'sections/languages_section.dart';
part 'sections/projects_section.dart';
part 'sections/sidebar_section.dart';
part 'sections/skills_section.dart';
part 'sections/summary_section.dart';
part 'sections/text_helpers.dart';
part 'templates/ats_template.dart';
part 'templates/classique_template.dart';
part 'templates/creatif_template.dart';
part 'templates/executive_template.dart';
part 'templates/minimaliste_template.dart';
part 'templates/moderne_template.dart';
part 'templates/pdf_template.dart';
part 'theme/pdf_colors.dart';
part 'theme/pdf_layout.dart';
part 'theme/pdf_typography.dart';

class PdfRenderer {
  const PdfRenderer._();

  static Future<Uint8List> generate(Cv cv, [PdfTemplate? template]) async {
    final photo = await _loadPhoto(cv.personalInfo?.photoUrl);
    final theme = PdfTheme(
      accent: PdfColor.fromInt(cv.style.primaryColor.toARGB32()),
      photo: photo,
    );
    final document =
        (template ?? templateFor(cv.style.templateId)).build(cv, theme);
    return document.save();
  }

  static PdfTemplate templateFor(String templateId) => switch (templateId) {
        'classique' => const ClassiquePdfTemplate(),
        'minimaliste' => const MinimalistePdfTemplate(),
        'creatif' => const CreatifPdfTemplate(),
        'executive' => const ExecutivePdfTemplate(),
        'ats' => const AtsPdfTemplate(),
        _ => const ModernePdfTemplate(),
      };
}

Future<pw.MemoryImage?> _loadPhoto(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
  } catch (_) {
    return null;
  }
  return null;
}
