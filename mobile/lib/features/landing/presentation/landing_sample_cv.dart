/// Donnees factices du CV vitrine de la landing (issue #251).
///
/// Fixture dediee au mock decoratif de la section « apercu » : elle isole les
/// valeurs illustratives (competences, periode) hors du widget, sans dupliquer
/// les regles de rendu de `CvPreview`. Les libelles textuels viennent des ARB
/// (cles `sample*`, issue #166).
abstract final class LandingSampleCv {
  const LandingSampleCv._();

  /// Competences affichees en puces dans l'apercu.
  static const List<String> skills = [
    'Java',
    'Spring Boot',
    'Angular',
    'Flutter',
    'Docker',
  ];

  /// Periode illustrative de l'experience mise en avant.
  static const String experiencePeriod = '2024 - 2026';
}
