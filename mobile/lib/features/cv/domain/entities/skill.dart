import 'copy_with_sentinel.dart';

/// Competence d'un CV, entite de domaine immuable et pure.
final class Skill {
  final int? id;
  final String? nom;
  final int? niveau;
  final String? categorie;

  const Skill({
    this.id,
    this.nom,
    this.niveau,
    this.categorie,
  });

  Skill copyWith({
    Object? id = unsetSentinel,
    Object? nom = unsetSentinel,
    Object? niveau = unsetSentinel,
    Object? categorie = unsetSentinel,
  }) {
    return Skill(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      nom: identical(nom, unsetSentinel) ? this.nom : nom as String?,
      niveau: identical(niveau, unsetSentinel) ? this.niveau : niveau as int?,
      categorie: identical(categorie, unsetSentinel)
          ? this.categorie
          : categorie as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Skill &&
      other.id == id &&
      other.nom == nom &&
      other.niveau == niveau &&
      other.categorie == categorie;

  @override
  int get hashCode => Object.hash(id, nom, niveau, categorie);
}
