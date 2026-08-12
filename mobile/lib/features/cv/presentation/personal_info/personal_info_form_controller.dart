import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../../features/cv/domain/entities/personal_info.dart';

/// Possede les `TextEditingController` du formulaire d'informations
/// personnelles, leur cycle de vie et la conversion vers [PersonalInfo]
/// (issue #242).
///
/// Extrait du `State` monolithique de `personal_info_section.dart` : la logique
/// de saisie devient testable sans widget ni `BuildContext`. Ne contient
/// AUCUNE dependance transport (upload, IA) ni UI ; ces responsabilites sont
/// portees par des use cases dedies (D4).
class PersonalInfoFormController {
  PersonalInfoFormController.fromPersonalInfo(PersonalInfo? info)
      : nom = TextEditingController(text: info?.nom),
        prenom = TextEditingController(text: info?.prenom),
        email = TextEditingController(text: info?.email),
        telephone = TextEditingController(text: info?.telephone),
        adresse = TextEditingController(text: info?.adresse),
        ville = TextEditingController(text: info?.ville),
        codePostal = TextEditingController(text: info?.codePostal),
        pays = TextEditingController(text: info?.pays),
        titrePoste = TextEditingController(text: info?.titrePoste),
        linkedIn = TextEditingController(text: info?.linkedIn),
        portfolio = TextEditingController(text: info?.portfolio),
        resume = TextEditingController(text: info?.resumeProfessionnel),
        photoUrl = info?.photoUrl;

  final TextEditingController nom;
  final TextEditingController prenom;
  final TextEditingController email;
  final TextEditingController telephone;
  final TextEditingController adresse;
  final TextEditingController ville;
  final TextEditingController codePostal;
  final TextEditingController pays;
  final TextEditingController titrePoste;
  final TextEditingController linkedIn;
  final TextEditingController portfolio;
  final TextEditingController resume;

  /// URL absolue de la photo uploadee (null si aucune / supprimee).
  String? photoUrl;

  /// Octets de la photo pour l'apercu local immediat (web notamment), avant
  /// ou en l'absence d'upload. N'est pas serialise dans [PersonalInfo].
  Uint8List? photoBytes;

  /// Efface la photo (url + apercu local).
  void clearPhoto() {
    photoUrl = null;
    photoBytes = null;
  }

  /// Construit un [PersonalInfo] a partir de l'etat courant. Les champs vides
  /// deviennent `null` (comportement historique de `_notify`).
  PersonalInfo toPersonalInfo() => PersonalInfo(
        nom: _nullIfEmpty(nom),
        prenom: _nullIfEmpty(prenom),
        email: _nullIfEmpty(email),
        telephone: _nullIfEmpty(telephone),
        adresse: _nullIfEmpty(adresse),
        ville: _nullIfEmpty(ville),
        codePostal: _nullIfEmpty(codePostal),
        pays: _nullIfEmpty(pays),
        titrePoste: _nullIfEmpty(titrePoste),
        linkedIn: _nullIfEmpty(linkedIn),
        portfolio: _nullIfEmpty(portfolio),
        resumeProfessionnel: _nullIfEmpty(resume),
        photoUrl: photoUrl,
      );

  static String? _nullIfEmpty(TextEditingController c) =>
      c.text.isNotEmpty ? c.text : null;

  /// Libere les 12 controllers. A appeler depuis `State.dispose`.
  void dispose() {
    nom.dispose();
    prenom.dispose();
    email.dispose();
    telephone.dispose();
    adresse.dispose();
    ville.dispose();
    codePostal.dispose();
    pays.dispose();
    titrePoste.dispose();
    linkedIn.dispose();
    portfolio.dispose();
    resume.dispose();
  }
}
