import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<int>> renderSection(pw.Widget section) async {
  final document = pw.Document()
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => section,
      ),
    );
  return document.save();
}

const sectionAccent = PdfColors.blue700;
