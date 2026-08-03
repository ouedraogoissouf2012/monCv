/// Champ de CV concerne par une amelioration IA (issue #244).
///
/// Identifiant STABLE et localise-agnostique : le use case de diff ne connait
/// pas les libelles traduits ; la presentation mappe [EnhancementField]
/// (+ [EnhancementChange.index]) vers le texte affiche.
enum EnhancementField {
  jobTitle,
  professionalSummary,
  experiencePoste,
  experienceDescription,
  educationEtablissement,
  educationDiplome,
  educationDomaine,
  educationDescription,
  skill,
  language,
  certificationNom,
  certificationOrganisme,
  projectNom,
  projectTechnologies,
  projectDescription,
}

/// Un changement propose par l'IA sur un champ precis (issue #244).
///
/// Immuable et Dart pur. [before] est la valeur d'origine, [after] la valeur
/// amelioree ; par construction du diff, [after] est non vide et different de
/// [before] (un champ inchange ne produit pas de [EnhancementChange]).
/// [index] repere l'element dans les sections en liste (0 pour les champs
/// uniques comme le titre).
class EnhancementChange {
  const EnhancementChange({
    required this.field,
    required this.before,
    required this.after,
    this.index = 0,
  });

  final EnhancementField field;
  final String before;
  final String after;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is EnhancementChange &&
      other.field == field &&
      other.before == before &&
      other.after == after &&
      other.index == index;

  @override
  int get hashCode => Object.hash(field, before, after, index);

  @override
  String toString() =>
      'EnhancementChange(${field.name}[$index]: "$before" -> "$after")';
}
