import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('EducationSection produit un bloc PDF', () async {
    final bytes = await renderSection(
      EducationSection.build(
        Education(diplome: 'Master', etablissement: 'Universite'),
        sectionAccent,
      ),
    );
    expect(bytes.length, greaterThan(500));
  });
}
