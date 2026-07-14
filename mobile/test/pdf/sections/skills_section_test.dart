import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('SkillsSection conserve les niveaux', () async {
    final bytes = await renderSection(
      SkillsSection.build([Skill(nom: 'Flutter', niveau: 4)], sectionAccent),
    );
    expect(bytes.length, greaterThan(500));
  });
}
