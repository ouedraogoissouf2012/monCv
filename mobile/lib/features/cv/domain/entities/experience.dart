import 'copy_with_sentinel.dart';

/// Experience professionnelle d'un CV, entite de domaine immuable et pure.
final class Experience {
  final int? id;
  final String? entreprise;
  final String? poste;
  final String? lieu;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? description;
  final bool actuel;

  const Experience({
    this.id,
    this.entreprise,
    this.poste,
    this.lieu,
    this.dateDebut,
    this.dateFin,
    this.description,
    this.actuel = false,
  });

  Experience copyWith({
    Object? id = unsetSentinel,
    Object? entreprise = unsetSentinel,
    Object? poste = unsetSentinel,
    Object? lieu = unsetSentinel,
    Object? dateDebut = unsetSentinel,
    Object? dateFin = unsetSentinel,
    Object? description = unsetSentinel,
    bool? actuel,
  }) {
    return Experience(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      entreprise: identical(entreprise, unsetSentinel)
          ? this.entreprise
          : entreprise as String?,
      poste: identical(poste, unsetSentinel) ? this.poste : poste as String?,
      lieu: identical(lieu, unsetSentinel) ? this.lieu : lieu as String?,
      dateDebut: identical(dateDebut, unsetSentinel)
          ? this.dateDebut
          : dateDebut as DateTime?,
      dateFin: identical(dateFin, unsetSentinel)
          ? this.dateFin
          : dateFin as DateTime?,
      description: identical(description, unsetSentinel)
          ? this.description
          : description as String?,
      actuel: actuel ?? this.actuel,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Experience &&
      other.id == id &&
      other.entreprise == entreprise &&
      other.poste == poste &&
      other.lieu == lieu &&
      other.dateDebut == dateDebut &&
      other.dateFin == dateFin &&
      other.description == description &&
      other.actuel == actuel;

  @override
  int get hashCode => Object.hash(
        id,
        entreprise,
        poste,
        lieu,
        dateDebut,
        dateFin,
        description,
        actuel,
      );
}
