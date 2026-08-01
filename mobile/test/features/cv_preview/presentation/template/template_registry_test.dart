import 'package:cv_mobile/features/cv_preview/domain/cv_document_view_model.dart';
import 'package:cv_mobile/features/cv_preview/presentation/template/cv_preview_template.dart';
import 'package:cv_mobile/features/cv_preview/presentation/template/template_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTemplate extends CvPreviewTemplate {
  const _FakeTemplate(this.id);

  @override
  final String id;

  @override
  Widget build(BuildContext context, CvDocumentViewModel document) =>
      const SizedBox.shrink();
}

void main() {
  const moderne = _FakeTemplate('moderne');
  const classique = _FakeTemplate('classique');

  CvPreviewTemplateRegistry registry() => CvPreviewTemplateRegistry(
        fallback: moderne,
        templates: const [classique],
      );

  test('resout un id connu vers son template (#243 E1)', () {
    expect(registry().resolve('classique'), same(classique));
  });

  test('id inconnu -> fallback (#243 E1)', () {
    expect(registry().resolve('inexistant'), same(moderne));
  });

  test('id null -> fallback (#243 E1)', () {
    expect(registry().resolve(null), same(moderne));
  });

  test('le fallback est aussi resolvable par son id', () {
    expect(registry().resolve('moderne'), same(moderne));
  });

  test('register ajoute un template sans toucher aux autres (#243)', () {
    final r = registry();
    const ats = _FakeTemplate('ats');
    r.register(ats);

    expect(r.resolve('ats'), same(ats));
    // Les templates existants restent intacts.
    expect(r.resolve('classique'), same(classique));
    expect(r.ids, containsAll(<String>['moderne', 'classique', 'ats']));
  });

  test('register remplace un template de meme id', () {
    final r = registry();
    const autreClassique = _FakeTemplate('classique');
    r.register(autreClassique);
    expect(r.resolve('classique'), same(autreClassique));
  });
}
