import 'copy_with_sentinel.dart';

/// Certification d'un CV, entite de domaine immuable et pure.
final class Certification {
  final int? id;
  final String? nom;
  final String? organisme;
  final DateTime? dateObtention;
  final DateTime? dateExpiration;
  final String? credentialUrl;

  const Certification({
    this.id,
    this.nom,
    this.organisme,
    this.dateObtention,
    this.dateExpiration,
    this.credentialUrl,
  });

  Certification copyWith({
    Object? id = unsetSentinel,
    Object? nom = unsetSentinel,
    Object? organisme = unsetSentinel,
    Object? dateObtention = unsetSentinel,
    Object? dateExpiration = unsetSentinel,
    Object? credentialUrl = unsetSentinel,
  }) {
    return Certification(
      id: identical(id, unsetSentinel) ? this.id : id as int?,
      nom: identical(nom, unsetSentinel) ? this.nom : nom as String?,
      organisme: identical(organisme, unsetSentinel)
          ? this.organisme
          : organisme as String?,
      dateObtention: identical(dateObtention, unsetSentinel)
          ? this.dateObtention
          : dateObtention as DateTime?,
      dateExpiration: identical(dateExpiration, unsetSentinel)
          ? this.dateExpiration
          : dateExpiration as DateTime?,
      credentialUrl: identical(credentialUrl, unsetSentinel)
          ? this.credentialUrl
          : credentialUrl as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Certification &&
      other.id == id &&
      other.nom == nom &&
      other.organisme == organisme &&
      other.dateObtention == dateObtention &&
      other.dateExpiration == dateExpiration &&
      other.credentialUrl == credentialUrl;

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        organisme,
        dateObtention,
        dateExpiration,
        credentialUrl,
      );
}
