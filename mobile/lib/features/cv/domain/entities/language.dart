import 'copy_with_sentinel.dart';

/// Langue d'un CV, entite de domaine immuable et pure.
final class Language {
  final int? id;
  final String? langue;
  final String? niveau;

  const Language({
    this.id,
    this.langue,
    this.niveau,
  });

  Language copyWith({
    Object? id = unsetSentinel,
    Object? langue = unsetSentinel,
    Object? niveau = unsetSentinel,
  }) {
    return Language(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      langue: identical(langue, unsetSentinel) ? this.langue : langue as String?,
      niveau: identical(niveau, unsetSentinel) ? this.niveau : niveau as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Language &&
      other.id == id &&
      other.langue == langue &&
      other.niveau == niveau;

  @override
  int get hashCode => Object.hash(id, langue, niveau);
}
