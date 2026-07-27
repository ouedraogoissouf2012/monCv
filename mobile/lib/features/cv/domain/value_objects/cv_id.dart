/// Identifiant d'un CV persiste, sous forme de value object immuable.
///
/// Un CV non encore persiste n'a pas de [CvId] (l'entite expose `CvId?`).
/// La valeur strictement negative signale un identifiant temporaire attribue
/// hors ligne, en attente de synchronisation (voir la file de sync offline).
///
/// Type de domaine pur : aucune dependance a Flutter, HTTP ou JSON.
final class CvId {
  /// Valeur brute de l'identifiant. Jamais nulle : l'absence d'identifiant est
  /// representee par un `CvId?` null, pas par un [CvId] a valeur nulle.
  final int value;

  const CvId(this.value);

  /// True si l'identifiant est temporaire (attribue hors ligne, non synchronise).
  bool get isTemporary => value < 0;

  @override
  bool operator ==(Object other) => other is CvId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CvId($value)';
}
