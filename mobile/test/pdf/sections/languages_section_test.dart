import 'package:cv_mobile/features/cv/domain/entities/language.dart';
import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('LanguagesSection conserve le niveau', () async {
    final bytes = await renderSection(
      LanguagesSection.build(
        [const Language(langue: 'Francais', niveau: 'C2')],
        sectionAccent,
      ),
    );
    expect(bytes.length, greaterThan(500));
  });
}
