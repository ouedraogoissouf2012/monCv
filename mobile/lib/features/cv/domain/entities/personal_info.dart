import 'copy_with_sentinel.dart';

/// Informations personnelles d'un CV, entite de domaine immuable et pure.
///
/// Tous les champs sont optionnels. `copyWith` distingue « conserver »,
/// « remplacer » et « effacer » (voir [unsetSentinel]).
final class PersonalInfo {
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? photoUrl;
  final String? linkedIn;
  final String? portfolio;
  final String? titrePoste;
  final String? resumeProfessionnel;

  const PersonalInfo({
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.ville,
    this.codePostal,
    this.pays,
    this.photoUrl,
    this.linkedIn,
    this.portfolio,
    this.titrePoste,
    this.resumeProfessionnel,
  });

  /// Nom complet lisible : « prenom nom » si les deux existent, sinon celui
  /// qui est present, sinon chaine vide.
  String get fullName {
    if (prenom != null && nom != null) return '$prenom $nom';
    return prenom ?? nom ?? '';
  }

  PersonalInfo copyWith({
    Object? nom = unsetSentinel,
    Object? prenom = unsetSentinel,
    Object? email = unsetSentinel,
    Object? telephone = unsetSentinel,
    Object? adresse = unsetSentinel,
    Object? ville = unsetSentinel,
    Object? codePostal = unsetSentinel,
    Object? pays = unsetSentinel,
    Object? photoUrl = unsetSentinel,
    Object? linkedIn = unsetSentinel,
    Object? portfolio = unsetSentinel,
    Object? titrePoste = unsetSentinel,
    Object? resumeProfessionnel = unsetSentinel,
  }) {
    return PersonalInfo(
      nom: identical(nom, unsetSentinel) ? this.nom : nom as String?,
      prenom: identical(prenom, unsetSentinel) ? this.prenom : prenom as String?,
      email: identical(email, unsetSentinel) ? this.email : email as String?,
      telephone: identical(telephone, unsetSentinel)
          ? this.telephone
          : telephone as String?,
      adresse:
          identical(adresse, unsetSentinel) ? this.adresse : adresse as String?,
      ville: identical(ville, unsetSentinel) ? this.ville : ville as String?,
      codePostal: identical(codePostal, unsetSentinel)
          ? this.codePostal
          : codePostal as String?,
      pays: identical(pays, unsetSentinel) ? this.pays : pays as String?,
      photoUrl: identical(photoUrl, unsetSentinel)
          ? this.photoUrl
          : photoUrl as String?,
      linkedIn: identical(linkedIn, unsetSentinel)
          ? this.linkedIn
          : linkedIn as String?,
      portfolio: identical(portfolio, unsetSentinel)
          ? this.portfolio
          : portfolio as String?,
      titrePoste: identical(titrePoste, unsetSentinel)
          ? this.titrePoste
          : titrePoste as String?,
      resumeProfessionnel: identical(resumeProfessionnel, unsetSentinel)
          ? this.resumeProfessionnel
          : resumeProfessionnel as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PersonalInfo &&
      other.nom == nom &&
      other.prenom == prenom &&
      other.email == email &&
      other.telephone == telephone &&
      other.adresse == adresse &&
      other.ville == ville &&
      other.codePostal == codePostal &&
      other.pays == pays &&
      other.photoUrl == photoUrl &&
      other.linkedIn == linkedIn &&
      other.portfolio == portfolio &&
      other.titrePoste == titrePoste &&
      other.resumeProfessionnel == resumeProfessionnel;

  @override
  int get hashCode => Object.hashAll([
        nom,
        prenom,
        email,
        telephone,
        adresse,
        ville,
        codePostal,
        pays,
        photoUrl,
        linkedIn,
        portfolio,
        titrePoste,
        resumeProfessionnel,
      ]);
}
