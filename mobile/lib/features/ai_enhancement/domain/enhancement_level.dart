/// Niveau d'amelioration IA d'un CV (issue #244).
///
/// Remplace les chaines magiques 'LITE'/'MEDIUM'/'MAX' dispersees dans la
/// presentation. [backendId] est l'identifiant EXACT attendu par le contrat
/// backend (aucun changement de contrat) ; c'est la seule representation
/// texte autorisee a sortir vers le transport.
enum EnhancementLevel {
  /// Relecture seule : orthographe/grammaire, sans reecriture.
  lite('LITE'),

  /// Amelioration standard : reformulations mesurees.
  medium('MEDIUM'),

  /// Amelioration maximale : reecriture la plus poussee.
  max('MAX');

  const EnhancementLevel(this.backendId);

  /// Identifiant du contrat backend (`/ai/enhance-cv`).
  final String backendId;

  /// Resout un [backendId] vers son niveau ; [fallback] si inconnu/null.
  static EnhancementLevel fromBackendId(String? id,
      {EnhancementLevel fallback = EnhancementLevel.medium}) {
    for (final level in values) {
      if (level.backendId == id) return level;
    }
    return fallback;
  }
}
