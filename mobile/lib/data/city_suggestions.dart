const Map<String, List<String>> citySuggestionsByCountry = {
  "Côte d'Ivoire": [
    'Abengourou',
    'Abidjan',
    'Agboville',
    'Bondoukou',
    'Bouaké',
    'Daloa',
    'Divo',
    'Gagnoa',
    'Grand-Bassam',
    'Korhogo',
    'Man',
    'Odienné',
    'San-Pédro',
    'Séguéla',
    'Soubré',
    'Yamoussoukro',
  ],
  'Burkina Faso': [
    'Banfora',
    'Bobo-Dioulasso',
    'Dédougou',
    "Fada N'Gourma",
    'Gaoua',
    'Kaya',
    'Koudougou',
    'Ouagadougou',
    'Ouahigouya',
    'Tenkodogo',
  ],
  'Sénégal': [
    'Dakar',
    'Diourbel',
    'Kaolack',
    'Kolda',
    'Louga',
    'Mbour',
    'Saint-Louis',
    'Thiès',
    'Touba',
    'Ziguinchor',
  ],
  'Mali': [
    'Bamako',
    'Gao',
    'Kayes',
    'Koutiala',
    'Mopti',
    'San',
    'Ségou',
    'Sikasso',
    'Tombouctou',
  ],
  'Bénin': [
    'Abomey-Calavi',
    'Bohicon',
    'Cotonou',
    'Djougou',
    'Natitingou',
    'Ouidah',
    'Parakou',
    'Porto-Novo',
  ],
  'Togo': [
    'Atakpamé',
    'Dapaong',
    'Kara',
    'Kpalimé',
    'Lomé',
    'Sokodé',
    'Tsévié',
  ],
  'Niger': [
    'Agadez',
    'Diffa',
    'Dosso',
    'Maradi',
    'Niamey',
    'Tahoua',
    'Zinder',
  ],
  'Guinée': [
    'Boké',
    'Conakry',
    'Faranah',
    'Kankan',
    'Kindia',
    'Labé',
    'Mamou',
    'Nzérékoré',
  ],
  'Ghana': [
    'Accra',
    'Cape Coast',
    'Ho',
    'Koforidua',
    'Kumasi',
    'Sunyani',
    'Takoradi',
    'Tamale',
    'Tema',
  ],
  'Nigéria': [
    'Abuja',
    'Benin City',
    'Enugu',
    'Ibadan',
    'Ilorin',
    'Jos',
    'Kaduna',
    'Kano',
    'Lagos',
    'Port Harcourt',
  ],
  'Cameroun': [
    'Bafoussam',
    'Bamenda',
    'Bertoua',
    'Douala',
    'Garoua',
    'Kribi',
    'Limbé',
    'Maroua',
    'Ngaoundéré',
    'Yaoundé',
  ],
  'Mauritanie': [
    'Atar',
    'Kaédi',
    'Kiffa',
    'Nouadhibou',
    'Nouakchott',
    'Rosso',
  ],
  'Gabon': [
    'Franceville',
    'Lambaréné',
    'Libreville',
    'Moanda',
    'Mouila',
    'Oyem',
    'Port-Gentil',
  ],
  'Congo': [
    'Brazzaville',
    'Dolisie',
    'Nkayi',
    'Ouesso',
    'Owando',
    'Pointe-Noire',
  ],
  'Maroc': [
    'Agadir',
    'Casablanca',
    'Fès',
    'Kénitra',
    'Marrakech',
    'Meknès',
    'Oujda',
    'Rabat',
    'Salé',
    'Tanger',
  ],
  'Algérie': [
    'Alger',
    'Annaba',
    'Batna',
    'Béjaïa',
    'Blida',
    'Constantine',
    'Oran',
    'Sétif',
    'Tlemcen',
  ],
  'Tunisie': [
    'Bizerte',
    'Gabès',
    'Kairouan',
    'Monastir',
    'Nabeul',
    'Sfax',
    'Sousse',
    'Tunis',
  ],
  'France': [
    'Bordeaux',
    'Grenoble',
    'Lille',
    'Lyon',
    'Marseille',
    'Montpellier',
    'Nantes',
    'Nice',
    'Paris',
    'Rennes',
    'Strasbourg',
    'Toulouse',
  ],
  'Belgique': [
    'Anvers',
    'Bruges',
    'Bruxelles',
    'Charleroi',
    'Gand',
    'Liège',
    'Mons',
    'Namur',
  ],
  'Suisse': [
    'Bâle',
    'Berne',
    'Fribourg',
    'Genève',
    'Lausanne',
    'Lucerne',
    'Neuchâtel',
    'Zurich',
  ],
  'Canada': [
    'Calgary',
    'Edmonton',
    'Gatineau',
    'Halifax',
    'Montréal',
    'Ottawa',
    'Québec',
    'Toronto',
    'Vancouver',
    'Winnipeg',
  ],
};

String normalizeLocationText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ýÿ]'), 'y')
      .replaceAll(RegExp(r"[-'’\s]+"), ' ');
}

bool hasCitySuggestionsForCountry(String country) {
  final normalizedCountry = normalizeLocationText(country);
  return normalizedCountry.isNotEmpty &&
      citySuggestionsByCountry.keys.any(
        (name) => normalizeLocationText(name) == normalizedCountry,
      );
}

List<String> findCitySuggestions({
  required String country,
  required String query,
  int limit = 8,
}) {
  final normalizedQuery = normalizeLocationText(query);
  if (normalizedQuery.isEmpty || country.trim().isEmpty || limit <= 0) {
    return const [];
  }

  final normalizedCountry = normalizeLocationText(country);
  final cities = citySuggestionsByCountry.entries
      .where((entry) => normalizeLocationText(entry.key) == normalizedCountry)
      .map((entry) => entry.value)
      .firstOrNull;

  if (cities == null) return const [];

  final matches = cities
      .where((city) => normalizeLocationText(city).contains(normalizedQuery))
      .toList();

  matches.sort((a, b) {
    final aKey = normalizeLocationText(a);
    final bKey = normalizeLocationText(b);
    final aStarts = aKey.startsWith(normalizedQuery);
    final bStarts = bKey.startsWith(normalizedQuery);
    if (aStarts != bStarts) return aStarts ? -1 : 1;
    return aKey.compareTo(bKey);
  });

  return matches.take(limit).toList(growable: false);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
