/// Helpers de (de)serialisation tolerants, partages par les mappers CV.
///
/// Objectif : neutraliser les entrees invalides (dates malformees, types
/// inattendus) sans lever d'exception, pour qu'un cache/reponse partiellement
/// corrompu ne fasse jamais crasher l'application.
library;

/// Parse une date ISO tolerante : renvoie `null` si absente ou invalide.
DateTime? parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Emet une date au format date-only `YYYY-MM-DD` (sans composante horaire),
/// conformement au contrat historique. `null` si la date est absente.
String? encodeDate(DateTime? date) => date?.toIso8601String().split('T').first;

/// Lit une chaine, ou `null` si la valeur n'est pas une chaine.
String? asString(Object? raw) => raw is String ? raw : null;

/// Lit un entier, ou `null` si la valeur n'est pas un entier.
int? asInt(Object? raw) => raw is int ? raw : null;

/// Lit un booleen avec valeur par defaut si absent/invalide.
bool asBool(Object? raw, {bool orElse = false}) => raw is bool ? raw : orElse;

/// Lit une liste de maps JSON, ou une liste vide si absente/non conforme.
List<Map<String, dynamic>> asJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}
