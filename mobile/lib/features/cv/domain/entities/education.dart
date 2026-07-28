import 'copy_with_sentinel.dart';

/// Formation d'un CV, entite de domaine immuable et pure.
final class Education {
  final int? id;
  final String? etablissement;
  final String? diplome;
  final String? domaine;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? description;

  const Education({
    this.id,
    this.etablissement,
    this.diplome,
    this.domaine,
    this.dateDebut,
    this.dateFin,
    this.description,
  });

  Education copyWith({
    Object? id = unsetSentinel,
    Object? etablissement = unsetSentinel,
    Object? diplome = unsetSentinel,
    Object? domaine = unsetSentinel,
    Object? dateDebut = unsetSentinel,
    Object? dateFin = unsetSentinel,
    Object? description = unsetSentinel,
  }) {
    return Education(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      etablissement: identical(etablissement, unsetSentinel)
          ? this.etablissement
          : etablissement as String?,
      diplome:
          identical(diplome, unsetSentinel) ? this.diplome : diplome as String?,
      domaine:
          identical(domaine, unsetSentinel) ? this.domaine : domaine as String?,
      dateDebut: identical(dateDebut, unsetSentinel)
          ? this.dateDebut
          : dateDebut as DateTime?,
      dateFin: identical(dateFin, unsetSentinel)
          ? this.dateFin
          : dateFin as DateTime?,
      description: identical(description, unsetSentinel)
          ? this.description
          : description as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Education &&
      other.id == id &&
      other.etablissement == etablissement &&
      other.diplome == diplome &&
      other.domaine == domaine &&
      other.dateDebut == dateDebut &&
      other.dateFin == dateFin &&
      other.description == description;

  @override
  int get hashCode => Object.hash(
        id,
        etablissement,
        diplome,
        domaine,
        dateDebut,
        dateFin,
        description,
      );
}
