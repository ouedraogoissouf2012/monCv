import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('ExperienceSection produit un bloc PDF', () async {
    final bytes = await renderSection(
      ExperienceSection.build(
        const Experience(poste: 'Developpeuse', entreprise: 'MonCV'),
        sectionAccent,
      ),
    );
    expect(bytes.length, greaterThan(500));
  });
}
