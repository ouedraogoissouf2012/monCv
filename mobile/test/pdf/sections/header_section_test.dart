import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('HeaderSection produit un bloc PDF', () async {
    final bytes = await renderSection(
      HeaderSection.build('Experience', sectionAccent),
    );
    expect(bytes.length, greaterThan(500));
  });
}
