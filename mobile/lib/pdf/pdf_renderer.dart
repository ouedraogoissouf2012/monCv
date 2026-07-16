import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv.dart';
import '../services/http_timeout.dart' as http;
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
  static Future<void>? _fontInitialization;

  static Future<Uint8List> generate(Cv cv, [PdfTemplate? template]) async {
    await (_fontInitialization ??= _initializeUnicodeFonts());
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

  static Future<void> _initializeUnicodeFonts() async {
    final fonts = await Future.wait([
      _downloadFont(
          'memSYaGs126MiZpBA-UvWbX2vVnXBbObj2OVZyOOSr4dVJWUgsjZ0C4nY1M2xLER.ttf'),
      _downloadFont(
          'memSYaGs126MiZpBA-UvWbX2vVnXBbObj2OVZyOOSr4dVJWUgsg-1y4nY1M2xLER.ttf'),
      _downloadFont(
          'memQYaGs126MiZpBA-UFUIcVXSCEkx2cmqvXlWq8tWZ0Pw86hd0Rk8ZkaVcUwaERZjA.ttf'),
      _downloadFont(
          'memQYaGs126MiZpBA-UFUIcVXSCEkx2cmqvXlWq8tWZ0Pw86hd0RkyFjaVcUwaERZjA.ttf'),
    ]);
    pw.ThemeData.buildThemeData = () => pw.ThemeData.withFont(
          base: fonts[0],
          bold: fonts[1],
          italic: fonts[2],
          boldItalic: fonts[3],
          fontFallback: [fonts[0]],
        );
  }

  static Future<pw.Font> _downloadFont(String name) async {
    final uri = Uri.https('fonts.gstatic.com', '/s/opensans/v40/$name');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw StateError('Impossible de charger la police PDF Unicode');
    }
    return pw.Font.ttf(ByteData.sublistView(response.bodyBytes));
  }
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
