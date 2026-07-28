import 'copy_with_sentinel.dart';

/// Projet d'un CV, entite de domaine immuable et pure.
final class Project {
  final int? id;
  final String? nom;
  final String? description;
  final String? technologies;
  final String? lien;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const Project({
    this.id,
    this.nom,
    this.description,
    this.technologies,
    this.lien,
    this.dateDebut,
    this.dateFin,
  });

  Project copyWith({
    Object? id = unsetSentinel,
    Object? nom = unsetSentinel,
    Object? description = unsetSentinel,
    Object? technologies = unsetSentinel,
    Object? lien = unsetSentinel,
    Object? dateDebut = unsetSentinel,
    Object? dateFin = unsetSentinel,
  }) {
    return Project(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      nom: identical(nom, unsetSentinel) ? this.nom : nom as String?,
      description: identical(description, unsetSentinel)
          ? this.description
          : description as String?,
      technologies: identical(technologies, unsetSentinel)
          ? this.technologies
          : technologies as String?,
      lien: identical(lien, unsetSentinel) ? this.lien : lien as String?,
      dateDebut: identical(dateDebut, unsetSentinel)
          ? this.dateDebut
          : dateDebut as DateTime?,
      dateFin: identical(dateFin, unsetSentinel)
          ? this.dateFin
          : dateFin as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.nom == nom &&
      other.description == description &&
      other.technologies == technologies &&
      other.lien == lien &&
      other.dateDebut == dateDebut &&
      other.dateFin == dateFin;

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        description,
        technologies,
        lien,
        dateDebut,
        dateFin,
      );
}
