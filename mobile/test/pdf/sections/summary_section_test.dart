import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'section_test_helpers.dart';

void main() {
  test('SummarySection transforme les lignes en widgets PDF', () async {
    final lines = SummarySection.build('- Resultat mesurable', sectionAccent);
    final bytes = await renderSection(pw.Column(children: lines));
    expect(bytes.length, greaterThan(500));
  });
}
