/// Metadonnees d'un pays : identifiant stable, nom localise et indicatif
/// telephonique (issue #242).
///
/// Source de verite unique remplacant les deux listes dupliquees de
/// `personal_info_section.dart` (`_countryDialCodes` nom->indicatif et
/// `_countries` liste d'affichage). Toute recherche se fait sur [id] (stable,
/// insensible casse/accents) et non sur le libelle FR, qui peut evoluer.
class CountryMetadata {
  const CountryMetadata({
    required this.id,
    required this.nameFr,
    required this.dialCode,
  });

  /// Identifiant stable : le nom FR normalise (sans accents, minuscules,
  /// espaces/apostrophes reduits). Ne change pas si l'affichage change de
  /// casse ou d'accentuation.
  final String id;

  /// Nom affiche (francais). Cle historique conservee pour compatibilite avec
  /// les CV existants et `citySuggestionsByCountry`.
  final String nameFr;

  /// Indicatif telephonique international, ex. `+225`.
  final String dialCode;

  /// Normalise une chaine pour comparaison/identifiant : minuscules, sans
  /// diacritiques, espaces et ponctuation de liaison reduits. Deterministe.
  static String normalize(String input) {
    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_stripDiacritic(String.fromCharCode(rune)));
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r"[\s'\-]+"), ' ')
        .trim();
  }

  /// Remplace un caractere accentue par son equivalent ASCII (couvre les
  /// diacritiques presents dans les noms de pays FR).
  static String _stripDiacritic(String ch) {
    const map = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ñ': 'n',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
    };
    return map[ch] ?? ch;
  }

  @override
  bool operator ==(Object other) =>
      other is CountryMetadata &&
      other.id == id &&
      other.nameFr == nameFr &&
      other.dialCode == dialCode;

  @override
  int get hashCode => Object.hash(id, nameFr, dialCode);

  @override
  String toString() => 'CountryMetadata($id, $nameFr, $dialCode)';
}
