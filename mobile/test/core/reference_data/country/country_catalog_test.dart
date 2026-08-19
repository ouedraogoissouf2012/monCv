import 'package:cv_mobile/core/reference_data/country/country_catalog.dart';
import 'package:cv_mobile/core/reference_data/country/country_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountryMetadata.normalize', () {
    test('supprime accents et casse', () {
      expect(CountryMetadata.normalize('Côte d\'Ivoire'),
          CountryMetadata.normalize('COTE D IVOIRE'));
      expect(CountryMetadata.normalize('Égypte'), 'egypte');
      expect(CountryMetadata.normalize('  Bénin  '), 'benin');
    });

    test('reduit espaces, tirets et apostrophes a un espace', () {
      expect(CountryMetadata.normalize('Bosnie-Herzégovine'),
          'bosnie herzegovine');
      expect(CountryMetadata.normalize("Côte d'Ivoire"), 'cote d ivoire');
    });

    test('est deterministe (idempotente sur un id deja normalise)', () {
      final once = CountryMetadata.normalize('Nouvelle-Zélande');
      expect(CountryMetadata.normalize(once), once);
    });
  });

  group('CountryCatalog - integrite des donnees (#242, anti-regression)', () {
    test('contient exactement 135 pays (aucune perte vs god-class)', () {
      expect(CountryCatalog.all, hasLength(135));
    });

    test('aucun identifiant en double', () {
      final ids = CountryCatalog.all.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('aucun nom FR en double', () {
      final names = CountryCatalog.displayNames;
      expect(names.toSet(), hasLength(names.length));
    });

    test('chaque indicatif est un + suivi de chiffres', () {
      for (final c in CountryCatalog.all) {
        expect(RegExp(r'^\+\d+$').hasMatch(c.dialCode), isTrue,
            reason: '${c.nameFr} a un indicatif invalide: ${c.dialCode}');
      }
    });

    test('indicatifs de reference preserves a l identique (echantillon)', () {
      // Verifie que la migration n a pas altere les indicatifs connus.
      expect(CountryCatalog.dialCodeFor('France'), '+33');
      expect(CountryCatalog.dialCodeFor("Côte d'Ivoire"), '+225');
      expect(CountryCatalog.dialCodeFor('Burkina Faso'), '+226');
      expect(CountryCatalog.dialCodeFor('Canada'), '+1');
      expect(CountryCatalog.dialCodeFor('Sénégal'), '+221');
    });
  });

  group('CountryCatalog - recherche par identifiant stable (#242)', () {
    test('byName insensible casse/accents', () {
      final ref = CountryCatalog.byName("Côte d'Ivoire");
      expect(ref, isNotNull);
      expect(CountryCatalog.byName('cote d ivoire'), ref);
      expect(CountryCatalog.byName('COTE D IVOIRE'), ref);
    });

    test('byId resout via l identifiant normalise', () {
      expect(CountryCatalog.byId('france')?.nameFr, 'France');
      expect(CountryCatalog.byId('FRANCE')?.nameFr, 'France');
    });

    test('dialCodeFor renvoie null pour un pays inconnu', () {
      expect(CountryCatalog.dialCodeFor('Atlantide'), isNull);
    });

    test('search filtre par prefixe insensible casse/accents', () {
      final results = CountryCatalog.search('bur');
      final names = results.map((c) => c.nameFr).toSet();
      expect(names, containsAll(<String>['Burkina Faso', 'Burundi']));
    });

    test('search avec accents dans la requete', () {
      // "sé" doit trouver Sénégal via la normalisation.
      final names =
          CountryCatalog.search('sé').map((c) => c.nameFr).toList();
      expect(names, contains('Sénégal'));
    });

    test('search vide -> aucune suggestion', () {
      expect(CountryCatalog.search(''), isEmpty);
      expect(CountryCatalog.search('   '), isEmpty);
    });

    test('search c ne propose que les pays commencant par c', () {
      final names = CountryCatalog.search('c').map((c) => c.nameFr).toList();
      expect(names, isNot(contains('Autriche')));
      expect(names.first, "Côte d'Ivoire");
      expect(names, containsAll(<String>['Cameroun', 'Canada', 'Congo']));
    });

    test('searchContains filtre par sous-chaine insensible casse/accents', () {
      // "ivoire" doit trouver "Cote d'Ivoire" (sous-chaine, pas prefixe).
      final names =
          CountryCatalog.searchContains('ivoire').map((c) => c.nameFr);
      expect(names, contains("Côte d'Ivoire"));
    });

    test('searchContains insensible aux accents dans la requete', () {
      // "gé" (accentue) doit trouver Géorgie et Nigéria via la normalisation.
      final names =
          CountryCatalog.searchContains('gé').map((c) => c.nameFr).toSet();
      expect(names, containsAll(<String>['Géorgie', 'Nigéria']));
    });

    test('searchContains vide -> aucune suggestion', () {
      expect(CountryCatalog.searchContains(''), isEmpty);
    });
  });
}
