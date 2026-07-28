import '../entities/cv.dart';

/// Poids (en points) de chaque critere de completion d'un CV.
///
/// La somme des poids par defaut vaut 100, mais toute configuration est
/// autorisee ; [CvCompletionPolicy.maxScore] recalcule le plafond.
typedef CvCompletionWeights = ({
  int titre,
  int identite,
  int email,
  int telephone,
  int titrePoste,
  int adresseOuVille,
  int resume,
  int experiences,
  int educations,
  int skills,
  int languages,
  int certifications,
  int projects,
});

/// Politique de calcul du score de completion d'un CV (bareme additif).
///
/// Extraite de l'ancien getter `Cv.completionScore` pour sortir la regle
/// metier de l'entite : la politique est pure, injectable et configurable.
/// Elle mesure la *presence* des sections/champs, independamment de leur
/// qualite (ce dernier aspect releve d'un autre service, hors de cette classe).
final class CvCompletionPolicy {
  final CvCompletionWeights weights;

  const CvCompletionPolicy({this.weights = _defaultWeights});

  static const CvCompletionWeights _defaultWeights = (
    titre: 10,
    identite: 10,
    email: 10,
    telephone: 5,
    titrePoste: 5,
    adresseOuVille: 5,
    resume: 10,
    experiences: 15,
    educations: 10,
    skills: 5,
    languages: 5,
    certifications: 5,
    projects: 5,
  );

  /// Score de completion, borne a `[0, maxScore]`.
  int score(CvEntity cv) {
    final info = cv.personalInfo;
    var total = 0;

    if (cv.titre.trim().isNotEmpty) total += weights.titre;
    if (_present(info?.prenom) && _present(info?.nom)) total += weights.identite;
    if (_present(info?.email)) total += weights.email;
    if (_present(info?.telephone)) total += weights.telephone;
    if (_present(info?.titrePoste)) total += weights.titrePoste;
    if (_present(info?.adresse) || _present(info?.ville)) {
      total += weights.adresseOuVille;
    }
    if (_present(info?.resumeProfessionnel)) total += weights.resume;
    if (cv.experiences.isNotEmpty) total += weights.experiences;
    if (cv.educations.isNotEmpty) total += weights.educations;
    if (cv.skills.isNotEmpty) total += weights.skills;
    if (cv.languages.isNotEmpty) total += weights.languages;
    if (cv.certifications.isNotEmpty) total += weights.certifications;
    if (cv.projects.isNotEmpty) total += weights.projects;

    return total.clamp(0, maxScore);
  }

  /// Plafond theorique, somme des poids configures.
  int get maxScore =>
      weights.titre +
      weights.identite +
      weights.email +
      weights.telephone +
      weights.titrePoste +
      weights.adresseOuVille +
      weights.resume +
      weights.experiences +
      weights.educations +
      weights.skills +
      weights.languages +
      weights.certifications +
      weights.projects;

  static bool _present(String? value) => value != null && value.isNotEmpty;
}
