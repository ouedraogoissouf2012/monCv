import '../../domain/entities/certification.dart';
import '../../domain/entities/education.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/skill.dart';
import 'json_codec_helpers.dart';

/// Convertit les sous-sections d'un CV entre JSON et entites de domaine.
///
/// Confine toute connaissance du format JSON des sous-sections dans la couche
/// data. Le parsing est tolerant (dates/types invalides neutralises via
/// [json_codec_helpers]). L'ordre d'insertion des collections est preserve.
final class CvSectionMapper {
  const CvSectionMapper();

  // ── PersonalInfo ────────────────────────────────────────────────
  PersonalInfo personalInfoFromJson(Map<String, dynamic> json) => PersonalInfo(
        nom: asString(json['nom']),
        prenom: asString(json['prenom']),
        email: asString(json['email']),
        telephone: asString(json['telephone']),
        adresse: asString(json['adresse']),
        ville: asString(json['ville']),
        codePostal: asString(json['codePostal']),
        pays: asString(json['pays']),
        photoUrl: asString(json['photoUrl']),
        linkedIn: asString(json['linkedIn']),
        portfolio: asString(json['portfolio']),
        titrePoste: asString(json['titrePoste']),
        resumeProfessionnel: asString(json['resumeProfessionnel']),
      );

  Map<String, dynamic> personalInfoToJson(PersonalInfo info) => {
        'nom': info.nom,
        'prenom': info.prenom,
        'email': info.email,
        'telephone': info.telephone,
        'adresse': info.adresse,
        'ville': info.ville,
        'codePostal': info.codePostal,
        'pays': info.pays,
        'photoUrl': info.photoUrl,
        'linkedIn': info.linkedIn,
        'portfolio': info.portfolio,
        'titrePoste': info.titrePoste,
        'resumeProfessionnel': info.resumeProfessionnel,
      };

  // ── Education ───────────────────────────────────────────────────
  Education educationFromJson(Map<String, dynamic> json) => Education(
        id: asInt(json['id']),
        etablissement: asString(json['etablissement']),
        diplome: asString(json['diplome']),
        domaine: asString(json['domaine']),
        dateDebut: parseDate(json['dateDebut']),
        dateFin: parseDate(json['dateFin']),
        description: asString(json['description']),
      );

  Map<String, dynamic> educationToJson(Education e) => {
        if (e.id != null) 'id': e.id,
        'etablissement': e.etablissement,
        'diplome': e.diplome,
        'domaine': e.domaine,
        'dateDebut': encodeDate(e.dateDebut),
        'dateFin': encodeDate(e.dateFin),
        'description': e.description,
      };

  // ── Experience ──────────────────────────────────────────────────
  Experience experienceFromJson(Map<String, dynamic> json) => Experience(
        id: asInt(json['id']),
        entreprise: asString(json['entreprise']),
        poste: asString(json['poste']),
        lieu: asString(json['lieu']),
        dateDebut: parseDate(json['dateDebut']),
        dateFin: parseDate(json['dateFin']),
        description: asString(json['description']),
        actuel: asBool(json['actuel']),
      );

  Map<String, dynamic> experienceToJson(Experience e) => {
        if (e.id != null) 'id': e.id,
        'entreprise': e.entreprise,
        'poste': e.poste,
        'lieu': e.lieu,
        'dateDebut': encodeDate(e.dateDebut),
        'dateFin': encodeDate(e.dateFin),
        'description': e.description,
        'actuel': e.actuel,
      };

  // ── Skill ───────────────────────────────────────────────────────
  Skill skillFromJson(Map<String, dynamic> json) => Skill(
        id: asInt(json['id']),
        nom: asString(json['nom']),
        niveau: asInt(json['niveau']),
        categorie: asString(json['categorie']),
      );

  Map<String, dynamic> skillToJson(Skill s) => {
        if (s.id != null) 'id': s.id,
        'nom': s.nom,
        'niveau': s.niveau,
        'categorie': s.categorie,
      };

  // ── Language ────────────────────────────────────────────────────
  Language languageFromJson(Map<String, dynamic> json) => Language(
        id: asInt(json['id']),
        langue: asString(json['langue']),
        niveau: asString(json['niveau']),
      );

  Map<String, dynamic> languageToJson(Language l) => {
        if (l.id != null) 'id': l.id,
        'langue': l.langue,
        'niveau': l.niveau,
      };

  // ── Certification ───────────────────────────────────────────────
  Certification certificationFromJson(Map<String, dynamic> json) =>
      Certification(
        id: asInt(json['id']),
        nom: asString(json['nom']),
        organisme: asString(json['organisme']),
        dateObtention: parseDate(json['dateObtention']),
        dateExpiration: parseDate(json['dateExpiration']),
        credentialUrl: asString(json['credentialUrl']),
      );

  Map<String, dynamic> certificationToJson(Certification c) => {
        if (c.id != null) 'id': c.id,
        'nom': c.nom,
        'organisme': c.organisme,
        'dateObtention': encodeDate(c.dateObtention),
        'dateExpiration': encodeDate(c.dateExpiration),
        'credentialUrl': c.credentialUrl,
      };

  // ── Project ─────────────────────────────────────────────────────
  Project projectFromJson(Map<String, dynamic> json) => Project(
        id: asInt(json['id']),
        nom: asString(json['nom']),
        description: asString(json['description']),
        technologies: asString(json['technologies']),
        lien: asString(json['lien']),
        dateDebut: parseDate(json['dateDebut']),
        dateFin: parseDate(json['dateFin']),
      );

  Map<String, dynamic> projectToJson(Project p) => {
        if (p.id != null) 'id': p.id,
        'nom': p.nom,
        'description': p.description,
        'technologies': p.technologies,
        'lien': p.lien,
        'dateDebut': encodeDate(p.dateDebut),
        'dateFin': encodeDate(p.dateFin),
      };

  // ── Listes ──────────────────────────────────────────────────────
  List<Education> educationsFromJson(Object? raw) =>
      asJsonList(raw).map(educationFromJson).toList(growable: false);

  List<Experience> experiencesFromJson(Object? raw) =>
      asJsonList(raw).map(experienceFromJson).toList(growable: false);

  List<Skill> skillsFromJson(Object? raw) =>
      asJsonList(raw).map(skillFromJson).toList(growable: false);

  List<Language> languagesFromJson(Object? raw) =>
      asJsonList(raw).map(languageFromJson).toList(growable: false);

  List<Certification> certificationsFromJson(Object? raw) =>
      asJsonList(raw).map(certificationFromJson).toList(growable: false);

  List<Project> projectsFromJson(Object? raw) =>
      asJsonList(raw).map(projectFromJson).toList(growable: false);
}
