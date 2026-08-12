import 'package:cv_mobile/features/cv/domain/entities/project.dart';
import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_test_helpers.dart';

void main() {
  test('ProjectsSection produit un bloc PDF', () async {
    final bytes = await renderSection(
      ProjectsSection.build(
        const Project(nom: 'MonCV', description: 'Generateur de CV'),
        sectionAccent,
      ),
    );
    expect(bytes.length, greaterThan(500));
  });
}
