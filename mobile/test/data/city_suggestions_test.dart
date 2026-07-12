import 'package:cv_mobile/data/city_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findCitySuggestions', () {
    test('propose Abidjan pour la Côte d’Ivoire', () {
      final results = findCitySuggestions(
        country: "Côte d'Ivoire",
        query: 'abi',
      );

      expect(results, contains('Abidjan'));
    });

    test('ignore les accents et la casse', () {
      final results = findCitySuggestions(
        country: 'cote d ivoire',
        query: 'SAN PED',
      );

      expect(results, contains('San-Pédro'));
    });

    test('filtre selon le pays sélectionné', () {
      final burkina = findCitySuggestions(
        country: 'Burkina Faso',
        query: 'bo',
      );
      final ivoire = findCitySuggestions(
        country: "Côte d'Ivoire",
        query: 'bo',
      );

      expect(burkina, contains('Bobo-Dioulasso'));
      expect(burkina, isNot(contains('Bouaké')));
      expect(ivoire, contains('Bouaké'));
    });

    test('retourne une liste vide pour un pays non couvert', () {
      expect(
        findCitySuggestions(country: 'Japon', query: 'tok'),
        isEmpty,
      );
    });
  });
}
