import 'country_catalog_data.dart';
import 'country_metadata.dart';

/// Acces en lecture au catalogue des pays (issue #242).
///
/// Source de verite unique : remplace `_countryDialCodes` et `_countries` de
/// `personal_info_section.dart`. Toutes les recherches sont fondees sur
/// l'identifiant stable ([CountryMetadata.id], insensible casse/accents), pas
/// sur le libelle FR.
class CountryCatalog {
  const CountryCatalog._();

  /// Toutes les entrees, dans l'ordre d'affichage historique (par nom FR).
  static List<CountryMetadata> get all => kCountryCatalog;

  /// Noms FR pour l'autocompletion / la liste d'affichage.
  static List<String> get displayNames =>
      kCountryCatalog.map((c) => c.nameFr).toList(growable: false);

  /// Recherche par identifiant stable normalise. `null` si absent.
  static CountryMetadata? byId(String id) {
    final needle = CountryMetadata.normalize(id);
    for (final country in kCountryCatalog) {
      if (country.id == needle) return country;
    }
    return null;
  }

  /// Recherche a partir d'un libelle quelconque (nom FR saisi, casse/accents
  /// indifferents). Passe par la normalisation, donc "cote d'ivoire",
  /// "Côte d'Ivoire" et "COTE D IVOIRE" resolvent la meme entree.
  static CountryMetadata? byName(String name) => byId(name);

  /// Indicatif telephonique pour un libelle de pays, ou `null` si inconnu.
  /// Remplace l'ancien acces direct `_countryDialCodes[pays]`.
  static String? dialCodeFor(String name) => byName(name)?.dialCode;

  /// Filtre les pays dont le nom commence par [query] (insensible
  /// casse/accents). [query] vide -> liste vide (pas de suggestion parasite).
  static const _zonePriority = {
    'cote d ivoire',
    'senegal',
    'mali',
    'burkina faso',
    'benin',
    'togo',
    'niger',
    'guinee',
    'cameroun',
    'congo',
    'gabon',
    'tchad',
    'france',
    'belgique',
    'suisse',
    'canada',
    'maroc',
    'algerie',
    'tunisie',
  };

  static List<CountryMetadata> search(String query) {
    final needle = CountryMetadata.normalize(query);
    if (needle.isEmpty) return const [];
    final prefix = kCountryCatalog.where((c) => c.id.startsWith(needle)).toList();
    prefix.sort((a, b) {
      int rank(CountryMetadata c) {
        if (c.id == 'cote d ivoire') return 0;
        if (_zonePriority.contains(c.id)) return 1;
        return 2;
      }

      final cmp = rank(a).compareTo(rank(b));
      return cmp != 0 ? cmp : a.nameFr.compareTo(b.nameFr);
    });
    return prefix;
  }

  /// Filtre les pays dont le nom CONTIENT [query] (insensible casse/accents).
  /// Conserve le comportement historique de l'autocompletion pays (recherche
  /// par sous-chaine), en gagnant l'insensibilite aux accents. [query] vide ->
  /// liste vide.
  static List<CountryMetadata> searchContains(String query) {
    final needle = CountryMetadata.normalize(query);
    if (needle.isEmpty) return const [];
    return kCountryCatalog
        .where((c) => c.id.contains(needle))
        .toList(growable: false);
  }
}
